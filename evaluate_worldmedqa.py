#!/usr/bin/env python3
"""
WorldMedQA Evaluation Script for MLX MedGemma Models

Evaluates the local MLX quantized vision-language models (4-bit, 6-bit, 8-bit)
on the WorldMedQA/V dataset - medical multiple-choice questions with images.

This tests the model's ability to read medical images and answer complex
clinical questions with multiple-choice options.

Usage:
    python3 evaluate_worldmedqa.py --model 4bit --samples 50
    python3 evaluate_worldmedqa.py --model all --samples 100
    python3 evaluate_worldmedqa.py --compare --samples 50

Requirements:
    - MLX and MLX-VLM frameworks
    - transformers library
    - huggingface_hub
    - datasets library
    - Pillow for image handling
"""

import argparse
import base64
import io
import json
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple

try:
    import mlx.core as mx
    from mlx_vlm import load, generate
except ImportError:
    print("❌ MLX frameworks not installed. Install with:")
    print("   pip install mlx mlx-vlm transformers huggingface-hub datasets")
    sys.exit(1)

try:
    from datasets import load_dataset
except ImportError:
    print("❌ datasets library not installed. Install with:")
    print("   pip install datasets")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("❌ Pillow library not installed. Install with:")
    print("   pip install Pillow")
    sys.exit(1)


class WorldMedQAEvaluator:
    """Evaluates MLX MedGemma models on WorldMedQA dataset"""

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
            self.model, self.processor = load(str(model_dir))
            print(f"✅ Model loaded successfully")
            return True
        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            return False

    def load_worldmedqa(self) -> bool:
        """Load WorldMedQA dataset"""
        print("\n🔄 Loading WorldMedQA/V dataset...")

        try:
            self.dataset = load_dataset("WorldMedQA/V")
            total = sum(len(self.dataset[split]) for split in self.dataset.keys())
            print(f"✅ WorldMedQA/V loaded: {total} samples available")
            return True
        except Exception as e:
            print(f"❌ Could not load WorldMedQA/V: {e}")
            return False

    def decode_image(self, image_data) -> Image.Image:
        """Decode image from base64 or PIL Image"""
        if isinstance(image_data, Image.Image):
            return image_data.convert('RGB')
        elif isinstance(image_data, str):
            # Base64 encoded image
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
            return image.convert('RGB')
        else:
            return None

    def evaluate_sample(self, sample: Dict) -> Tuple[str, float]:
        """
        Evaluate a single WorldMedQA sample.

        Args:
            sample: WorldMedQA sample with image, question, and correct_option

        Returns:
            Tuple of (predicted_answer, inference_time)
        """
        try:
            # Decode image
            image_data = sample.get("image")
            image = self.decode_image(image_data)
            if image is None:
                return "unknown", 0.0

            # Get question (includes options A, B, C, D)
            question = sample.get("question", "")

            # Create prompt asking model to select best answer
            user_prompt = f"""Based on the medical image and clinical context provided, 
select the correct answer from the options A, B, C, or D.

{question}

Your answer (A/B/C/D):"""

            # Use Gemma3 multimodal format with image token
            formatted_prompt = f"{self.processor.boi_token}\n{user_prompt}"

            try:
                start_time = time.time()

                # Generate response
                result = generate(
                    self.model,
                    self.processor,
                    formatted_prompt,
                    image=image,
                    max_tokens=5,
                    temperature=0.1
                )

                inference_time = time.time() - start_time

                # Extract answer from response (look for A, B, C, or D)
                response_text = result.text.upper().strip()
                predicted = "unknown"
                
                for letter in ['A', 'B', 'C', 'D']:
                    if letter in response_text:
                        predicted = letter
                        break

                return predicted, inference_time

            except Exception as e:
                print(f"   ⚠️  Inference error: {e}")
                return "unknown", 0.0

        except Exception as e:
            print(f"   ⚠️  Sample processing error: {e}")
            return "unknown", 0.0

    def run_evaluation(self) -> Dict:
        """Run evaluation on WorldMedQA dataset"""
        print(f"\n{'='*70}")
        print(f"  Evaluating {self.model_quantization} Model on WorldMedQA/V")
        print(f"{'='*70}\n")

        if not self.setup_model():
            return None

        if not self.load_worldmedqa():
            return None

        # Use train split
        split_name = 'train'
        dataset_split = self.dataset[split_name]
        
        # Determine samples to evaluate
        dataset_size = len(dataset_split)
        num_samples = self.max_samples if self.max_samples else dataset_size
        num_samples = min(num_samples, dataset_size)

        print(f"Evaluating on {num_samples} samples from '{split_name}' split...\n")

        for idx in range(num_samples):
            sample = dataset_split[idx]
            ground_truth = sample.get("correct_option", "unknown")

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

            # Extract question preview (first line)
            question_preview = sample.get("question", "")[:80]
            
            self.results["predictions"].append({
                "question": question_preview,
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
        evaluator = WorldMedQAEvaluator(model_quantization=quant, max_samples=max_samples)
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
        description="Evaluate MLX MedGemma models on WorldMedQA/V dataset"
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
        help="Number of samples to evaluate (default: 50)"
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
        evaluator = WorldMedQAEvaluator(model_quantization=args.model, max_samples=args.samples)
        metrics = evaluator.run_evaluation()
        evaluator.print_results()

        # Save results if requested
        if args.output and metrics:
            with open(args.output, 'w') as f:
                json.dump(metrics, f, indent=2)
            print(f"✅ Results saved to {args.output}")


if __name__ == "__main__":
    main()
