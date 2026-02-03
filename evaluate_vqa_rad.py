#!/usr/bin/env python3
"""
VQA-RAD Evaluation Script for MLX MedGemma Models

Evaluates the local MLX quantized vision-language models (4-bit, 6-bit, 8-bit)
on the VQA-RAD (Visual Question Answering on Radiology) dataset.

This tests the multimodal capabilities of the models on real medical images.

Usage:
    python3 evaluate_vqa_rad.py --model 4bit --samples 50
    python3 evaluate_vqa_rad.py --model all --samples 100
    python3 evaluate_vqa_rad.py --compare --samples 50

Requirements:
    - MLX and MLX-VLM frameworks
    - transformers library
    - huggingface_hub
    - datasets library
    - Pillow for image handling
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
    sys.exit(1)

try:
    from PIL import Image
    import io
except ImportError:
    print("❌ Pillow library not installed. Install with:")
    print("   pip install Pillow")
    sys.exit(1)


class VQARadEvaluator:
    """Evaluates MLX MedGemma models on VQA-RAD dataset"""

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

    def load_vqa_rad(self) -> bool:
        """Load VQA-RAD dataset"""
        print("\n🔄 Loading VQA-RAD dataset...")

        try:
            # Load VQA-RAD test split (includes image, question, answer)
            self.dataset = load_dataset("flaviagiammarino/vqa-rad", split="test")
            print(f"✅ VQA-RAD loaded: {len(self.dataset)} samples available")
            return True
        except Exception as e:
            print(f"❌ Could not load VQA-RAD: {e}")
            return False

    def evaluate_sample(self, sample: Dict) -> Tuple[str, float]:
        """
        Evaluate a single VQA-RAD sample.

        Args:
            sample: VQA-RAD sample with image, question, answer

        Returns:
            Tuple of (predicted_answer, inference_time)
        """
        try:
            # Get image and question
            image = sample.get("image")
            question = sample.get("question", "")

            # Convert image to RGB if needed
            if hasattr(image, 'convert'):
                image = image.convert('RGB')

            # Use Gemma3 multimodal format with image token
            # The boi_token (<start_of_image>) is required for image processing
            formatted_prompt = f"{self.processor.boi_token}\nQuestion: {question}\nAnswer:"

            try:
                start_time = time.time()

                # Generate response using MLX model with image
                result = generate(
                    self.model,
                    self.processor,
                    formatted_prompt,
                    image=image,
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

        except Exception as e:
            print(f"   ⚠️  Sample processing error: {e}")
            return "unknown", 0.0

    def run_evaluation(self) -> Dict:
        """Run evaluation on VQA-RAD dataset"""
        print(f"\n{'='*70}")
        print(f"  Evaluating {self.model_quantization} Model on VQA-RAD")
        print(f"{'='*70}\n")

        if not self.setup_model():
            return None

        if not self.load_vqa_rad():
            return None

        # Determine samples to evaluate
        dataset_size = len(self.dataset)
        num_samples = self.max_samples if self.max_samples else dataset_size
        num_samples = min(num_samples, dataset_size)

        print(f"Evaluating on {num_samples} samples...\n")

        for idx in range(num_samples):
            sample = self.dataset[idx]
            ground_truth = sample.get("answer", "unknown").lower()

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
        print(f"\nPredictions (first 5):")
        for pred in self.results['predictions'][:5]:
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
        evaluator = VQARadEvaluator(model_quantization=quant, max_samples=max_samples)
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
        description="Evaluate MLX MedGemma models on VQA-RAD dataset"
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
        default=50,
        help="Number of samples to evaluate (default: 50, 'all' for full dataset)"
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
        evaluator = VQARadEvaluator(model_quantization=args.model, max_samples=args.samples)
        metrics = evaluator.run_evaluation()
        evaluator.print_results()

        # Save results if requested
        if args.output and metrics:
            with open(args.output, 'w') as f:
                json.dump(metrics, f, indent=2)
            print(f"✅ Results saved to {args.output}")


if __name__ == "__main__":
    main()
