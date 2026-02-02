#!/usr/bin/env python3
"""
PubMedQA Evaluation Script for MLX MedGemma Models

Automatically scores the local MLX quantized models (4-bit, 6-bit, 8-bit)
against the PubMedQA biomedical question-answering dataset.

Usage:
    python3 evaluate_pubmedqa.py --model 4bit --samples 100
    python3 evaluate_pubmedqa.py --model all --samples all
    python3 evaluate_pubmedqa.py --compare

Requirements:
    - MLX and MLXVLM frameworks
    - transformers library
    - huggingface_hub
    - datasets library
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple
import subprocess

try:
    import mlx.core as mx
    from mlx_vlm import load, generate
except ImportError:
    print("❌ MLX frameworks not installed. Install with:")
    print("   pip install mlx mlx-vlm transformers huggingface-hub datasets")
    print("\nNote: Package name is 'mlx-vlm' (with hyphen), imports as 'mlx_vlm' (with underscore)")
    sys.exit(1)

try:
    from datasets import load_dataset
except ImportError:
    print("❌ datasets library not installed. Install with:")
    print("   pip install datasets")
    sys.exit(1)

try:
    from huggingface_hub import snapshot_download
except ImportError:
    print("❌ huggingface_hub library not installed. Install with:")
    print("   pip install huggingface-hub")
    print("\nNote: Package name is 'huggingface-hub' (with hyphen), not 'huggingface_hub'")
    sys.exit(1)


class PubMedQAEvaluator:
    """Evaluates MLX MedGemma models on PubMedQA dataset"""

    def __init__(self, model_quantization: str = "4bit", max_samples: int = None):
        """
        Initialize the evaluator with a specific model quantization.

        Args:
            model_quantization: "4bit", "6bit", or "8bit"
            max_samples: Maximum number of samples to evaluate (None = all)
        """
        self.model_quantization = model_quantization
        self.max_samples = max_samples
        self.model = None
        self.processor = None
        self.dataset = None
        self.results = {
            "correct": 0,
            "total": 0,
            "exact_matches": 0,
            "inference_times": [],
            "predictions": []
        }

    def setup_model(self) -> bool:
        """Load the MLX model from local directory"""
        print(f"\n🔄 Loading {self.model_quantization} model...")

        model_dir = Path.home() / "MediScribe" / "models" / f"medgemma-4b-it-{self.model_quantization}"

        if not model_dir.exists():
            print(f"❌ Model directory not found: {model_dir}")
            return False

        try:
            print(f"   Model path: {model_dir}")
            # Load model using MLX
            self.model, self.processor = load(str(model_dir))
            print(f"✅ Model loaded successfully")
            return True
        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            return False

    def load_pubmedqa(self) -> bool:
        """Load PubMedQA dataset"""
        print("\n🔄 Loading PubMedQA dataset...")

        try:
            # Load PubMedQA (includes question, context, long_answer, final_decision)
            self.dataset = load_dataset("pubmedqa", "pqa_artificial", split="train")
            print(f"✅ PubMedQA loaded: {len(self.dataset)} samples available")
            return True
        except Exception as e:
            print(f"⚠️  Could not load PubMedQA: {e}")
            print("   Attempting to create mock dataset for testing...")
            self._create_mock_dataset()
            return True

    def _create_mock_dataset(self):
        """Create mock dataset for testing when PubMedQA is unavailable"""
        self.dataset = [
            {
                "question": "Is there evidence for the efficacy of treatment A in condition B?",
                "context": "A randomized controlled trial was conducted...",
                "final_decision": "yes"
            },
            {
                "question": "Does drug X improve outcomes in disease Y?",
                "context": "In a systematic review of 15 studies...",
                "final_decision": "no"
            },
            {
                "question": "Is gene Z associated with condition C?",
                "context": "Multiple association studies have examined...",
                "final_decision": "maybe"
            }
        ]
        print("   Using 3-sample mock dataset")

    def evaluate_sample(self, sample: Dict) -> Tuple[str, float]:
        """
        Evaluate a single PubMedQA sample.

        Args:
            sample: PubMedQA sample with question, context, etc.

        Returns:
            Tuple of (predicted_answer, inference_time)
        """
        question = sample.get("question", "")
        context = sample.get("context", "")[:500]  # Limit context length

        # Format prompt for biomedical QA using Gemma3 chat format
        user_prompt = f"""Based on the following biomedical context, answer the question with yes, no, or maybe.

Context: {context}

Question: {question}

Answer (yes/no/maybe):"""

        # Use Gemma3 chat template format
        formatted_prompt = f"<start_of_turn>user\n{user_prompt}\n<end_of_turn>\n<start_of_turn>model\n"

        try:
            start_time = time.time()

            # Generate response using MLX model
            result = generate(
                self.model,
                self.processor,
                formatted_prompt,
                max_tokens=10,
                temperature=0.1
            )

            inference_time = time.time() - start_time

            # Extract answer from response
            response_text = result.text.lower().strip()
            if "yes" in response_text:
                predicted = "yes"
            elif "no" in response_text:
                predicted = "no"
            elif "maybe" in response_text:
                predicted = "maybe"
            else:
                predicted = "unknown"

            return predicted, inference_time

        except Exception as e:
            print(f"   ⚠️  Inference error: {e}")
            return "unknown", 0.0

    def run_evaluation(self) -> Dict:
        """Run evaluation on PubMedQA dataset"""
        print(f"\n{'='*70}")
        print(f"  Evaluating {self.model_quantization} Model on PubMedQA")
        print(f"{'='*70}\n")

        if not self.setup_model():
            return None

        if not self.load_pubmedqa():
            return None

        # Determine samples to evaluate
        dataset_size = len(self.dataset)
        num_samples = self.max_samples if self.max_samples else dataset_size
        num_samples = min(num_samples, dataset_size)

        print(f"Evaluating on {num_samples} samples...\n")

        for idx in range(num_samples):
            sample = self.dataset[idx]
            ground_truth = sample.get("final_decision", "unknown")

            # Get prediction
            predicted, inference_time = self.evaluate_sample(sample)

            # Record results
            self.results["total"] += 1
            self.results["inference_times"].append(inference_time)

            # Check if correct
            if predicted == ground_truth:
                self.results["correct"] += 1
                self.results["exact_matches"] += 1
                status = "✅"
            else:
                status = "❌"

            self.results["predictions"].append({
                "question": sample.get("question", "")[:100],
                "predicted": predicted,
                "ground_truth": ground_truth,
                "correct": predicted == ground_truth,
                "inference_time": inference_time
            })

            # Progress indicator
            if (idx + 1) % 10 == 0:
                accuracy = self.results["exact_matches"] / self.results["total"] * 100
                print(f"  [{idx + 1:4d}/{num_samples}] Accuracy: {accuracy:.1f}% "
                      f"({self.results['exact_matches']}/{self.results['total']})")

        return self._calculate_metrics()

    def _calculate_metrics(self) -> Dict:
        """Calculate evaluation metrics"""
        if self.results["total"] == 0:
            return None

        accuracy = self.results["exact_matches"] / self.results["total"] * 100
        avg_inference_time = sum(self.results["inference_times"]) / len(self.results["inference_times"])

        metrics = {
            "model": self.model_quantization,
            "total_samples": self.results["total"],
            "correct": self.results["exact_matches"],
            "accuracy": accuracy,
            "avg_inference_time_ms": avg_inference_time * 1000,
            "predictions": self.results["predictions"]
        }

        return metrics

    def print_results(self):
        """Print evaluation results"""
        if self.results["total"] == 0:
            print("❌ No results to display")
            return

        accuracy = self.results["exact_matches"] / self.results["total"] * 100
        avg_time = sum(self.results["inference_times"]) / len(self.results["inference_times"])

        print(f"\n{'='*70}")
        print(f"  RESULTS: {self.model_quantization} Quantization")
        print(f"{'='*70}")
        print(f"\nAccuracy: {self.results['exact_matches']}/{self.results['total']} ({accuracy:.1f}%)")
        print(f"Average Inference Time: {avg_time*1000:.2f} ms")
        print(f"Total Inference Time: {sum(self.results['inference_times']):.2f} seconds")
        print(f"\nPredictions:")
        for pred in self.results['predictions'][:5]:  # Show first 5
            status = "✅" if pred['correct'] else "❌"
            print(f"  {status} Q: {pred['question']}")
            print(f"      Predicted: {pred['predicted']}, Ground Truth: {pred['ground_truth']}")
        print()


def compare_quantizations(max_samples: int = None):
    """Compare all quantization levels"""
    print(f"\n{'='*70}")
    print("  COMPARING ALL QUANTIZATION LEVELS")
    print(f"{'='*70}\n")

    results = {}

    for quant in ["4bit", "6bit", "8bit"]:
        print(f"\n{'─'*70}")
        evaluator = PubMedQAEvaluator(model_quantization=quant, max_samples=max_samples)
        evaluator.run_evaluation()
        evaluator.print_results()
        results[quant] = evaluator.results

    # Summary comparison
    print(f"\n{'='*70}")
    print("  COMPARISON SUMMARY")
    print(f"{'='*70}\n")

    for quant in ["4bit", "6bit", "8bit"]:
        if results[quant]["total"] > 0:
            accuracy = results[quant]["exact_matches"] / results[quant]["total"] * 100
            avg_time = sum(results[quant]["inference_times"]) / len(results[quant]["inference_times"])
            print(f"{quant}: Accuracy={accuracy:.1f}%, "
                  f"Avg Time={avg_time*1000:.2f}ms, "
                  f"Samples={results[quant]['total']}")

    print()


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Evaluate MLX MedGemma models on PubMedQA dataset"
    )
    parser.add_argument(
        "--model",
        choices=["4bit", "6bit", "8bit", "all"],
        default="4bit",
        help="Which model quantization to evaluate (default: 4bit)"
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=100,
        help="Number of samples to evaluate (default: 100, 'all' for full dataset)"
    )
    parser.add_argument(
        "--compare",
        action="store_true",
        help="Compare all three quantization levels"
    )
    parser.add_argument(
        "--output",
        type=str,
        help="Save results to JSON file"
    )

    args = parser.parse_args()

    # Validate model directory exists
    models_dir = Path.home() / "MediScribe" / "models"
    if not models_dir.exists():
        print(f"❌ Models directory not found: {models_dir}")
        print("   Please ensure MLX models are downloaded to ~/MediScribe/models/")
        sys.exit(1)

    # Run evaluation
    if args.compare or args.model == "all":
        compare_quantizations(max_samples=args.samples if args.samples else None)
    else:
        evaluator = PubMedQAEvaluator(model_quantization=args.model, max_samples=args.samples)
        metrics = evaluator.run_evaluation()
        evaluator.print_results()

        # Save results if requested
        if args.output and metrics:
            with open(args.output, 'w') as f:
                json.dump(metrics, f, indent=2)
            print(f"✅ Results saved to {args.output}")


if __name__ == "__main__":
    main()
