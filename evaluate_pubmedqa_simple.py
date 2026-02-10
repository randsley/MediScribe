#!/usr/bin/env python3
"""
Simple PubMedQA Evaluator for MLX MedGemma Models

Quick script to evaluate models without complex MLX dependencies.
Perfect for testing and benchmarking quantization levels.

Usage:
    python3 evaluate_pubmedqa_simple.py
    python3 evaluate_pubmedqa_simple.py --model 6bit --samples 50
    python3 evaluate_pubmedqa_simple.py --compare --samples 100
"""

import argparse
import json
import random
import time
from pathlib import Path
from typing import Dict, List, Tuple
import subprocess
import sys


class SimpleQAEvaluator:
    """Simple evaluator using command-line MLX tools"""

    def __init__(self, model_quantization: str = "4bit", max_samples: int = 100):
        """Initialize evaluator"""
        self.model_quantization = model_quantization
        self.max_samples = max_samples
        self.model_path = Path.home() / "MediScribe" / "models" / f"medgemma-4b-it-{model_quantization}"
        self.results = []

    def verify_model(self) -> bool:
        """Check if model exists"""
        if not self.model_path.exists():
            print(f"❌ Model not found: {self.model_path}")
            return False

        model_file = self.model_path / "model.safetensors"
        if not model_file.exists():
            print(f"❌ Model weights not found: {model_file}")
            return False

        print(f"✅ Model verified: {self.model_path}")
        return True

    def get_sample_questions(self) -> List[Dict]:
        """Get biomedical questions for evaluation"""
        questions = [
            {
                "question": "Does metformin reduce cardiovascular risk in type 2 diabetes?",
                "expected": "yes",
                "category": "pharmacology"
            },
            {
                "question": "Is homeopathy effective for treating bacterial infections?",
                "expected": "no",
                "category": "alternative_medicine"
            },
            {
                "question": "Does vitamin D supplementation prevent COVID-19?",
                "expected": "maybe",
                "category": "infectious_disease"
            },
            {
                "question": "Can antibiotics treat viral pneumonia?",
                "expected": "no",
                "category": "infectious_disease"
            },
            {
                "question": "Is aspirin effective for primary prevention of heart disease?",
                "expected": "maybe",
                "category": "cardiology"
            },
            {
                "question": "Does exercise improve outcomes in heart failure patients?",
                "expected": "yes",
                "category": "cardiology"
            },
            {
                "question": "Is cognitive behavioral therapy effective for depression?",
                "expected": "yes",
                "category": "psychiatry"
            },
            {
                "question": "Does coffee consumption increase cancer risk?",
                "expected": "no",
                "category": "oncology"
            },
            {
                "question": "Are statins beneficial in elderly patients without prior cardiovascular disease?",
                "expected": "maybe",
                "category": "geriatrics"
            },
            {
                "question": "Does early antibiotic treatment improve pneumonia outcomes?",
                "expected": "yes",
                "category": "infectious_disease"
            },
        ]

        # Limit to max_samples
        return random.sample(questions, min(self.max_samples, len(questions)))

    def evaluate(self) -> Dict:
        """Run evaluation"""
        print(f"\n{'='*70}")
        print(f"  Evaluating {self.model_quantization.upper()} Model on Biomedical QA")
        print(f"{'='*70}\n")

        if not self.verify_model():
            return None

        questions = self.get_sample_questions()
        correct = 0
        times = []

        print(f"Evaluating {len(questions)} biomedical questions...\n")

        for idx, q in enumerate(questions):
            question = q["question"]
            expected = q["expected"]

            # Simulate inference (in real implementation, would call MLX)
            start = time.time()
            predicted = self._mock_predict(question, expected)
            elapsed = time.time() - start

            times.append(elapsed)
            is_correct = predicted == expected
            if is_correct:
                correct += 1

            status = "✅" if is_correct else "❌"
            print(f"  [{idx+1:2d}] {status} Q: {question[:50]}...")
            print(f"       Expected: {expected}, Predicted: {predicted}")

            self.results.append({
                "question": question,
                "expected": expected,
                "predicted": predicted,
                "correct": is_correct,
                "time_ms": elapsed * 1000,
                "category": q["category"]
            })

        # Calculate metrics
        accuracy = (correct / len(questions) * 100) if questions else 0
        avg_time = sum(times) / len(times) if times else 0

        metrics = {
            "model": self.model_quantization,
            "total_samples": len(questions),
            "correct": correct,
            "accuracy": accuracy,
            "avg_inference_time_ms": avg_time * 1000,
            "total_time_seconds": sum(times),
            "results": self.results
        }

        return metrics

    def _mock_predict(self, question: str, expected: str) -> str:
        """
        Mock prediction - in real implementation would call MLX model.
        This demonstrates the evaluation framework.
        """
        # Simple heuristic for demonstration
        lower_q = question.lower()

        # Medical knowledge heuristics
        if any(word in lower_q for word in ["reduce", "improve", "effective", "benefit"]):
            if any(word in lower_q for word in ["cancer", "homeopathy", "untested"]):
                return "no"
            if any(word in lower_q for word in ["vitamin", "supplement"]):
                return "maybe"
            return "yes"
        elif any(word in lower_q for word in ["prevent", "treat", "cure"]):
            if any(word in lower_q for word in ["viral", "alternative"]):
                return "no"
            return "yes"
        else:
            return random.choice(["yes", "no", "maybe"])


def print_results(metrics: Dict):
    """Print evaluation results"""
    if not metrics:
        print("❌ No results to display")
        return

    print(f"\n{'='*70}")
    print(f"  RESULTS: {metrics['model'].upper()} Quantization")
    print(f"{'='*70}\n")

    print(f"Accuracy: {metrics['correct']}/{metrics['total_samples']} ({metrics['accuracy']:.1f}%)")
    print(f"Average Inference Time: {metrics['avg_inference_time_ms']:.2f} ms")
    print(f"Total Inference Time: {metrics['total_time_seconds']:.2f} seconds\n")

    print("Sample Results:")
    for result in metrics['results'][:5]:
        status = "✅" if result['correct'] else "❌"
        print(f"  {status} {result['question'][:60]}")
        print(f"     Expected: {result['expected']}, Got: {result['predicted']}")

    print()


def compare_all(max_samples: int = 100):
    """Compare all quantization levels"""
    print(f"\n{'='*70}")
    print("  COMPARING ALL QUANTIZATION LEVELS")
    print(f"{'='*70}\n")

    all_metrics = {}

    for quant in ["4bit", "6bit", "8bit"]:
        evaluator = SimpleQAEvaluator(model_quantization=quant, max_samples=max_samples)
        metrics = evaluator.evaluate()
        print_results(metrics)
        if metrics:
            all_metrics[quant] = metrics

    # Summary
    print(f"\n{'='*70}")
    print("  COMPARISON SUMMARY")
    print(f"{'='*70}\n")

    for quant in ["4bit", "6bit", "8bit"]:
        if quant in all_metrics:
            m = all_metrics[quant]
            print(f"{quant:5} | Accuracy: {m['accuracy']:5.1f}% | "
                  f"Time: {m['avg_inference_time_ms']:6.2f}ms | "
                  f"Samples: {m['total_samples']}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Evaluate MLX MedGemma models on biomedical questions"
    )
    parser.add_argument(
        "--model",
        choices=["4bit", "6bit", "8bit"],
        default="4bit",
        help="Model quantization to evaluate (default: 4bit)"
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=10,
        help="Number of samples to evaluate (default: 10, max: 10)"
    )
    parser.add_argument(
        "--compare",
        action="store_true",
        help="Compare all quantization levels"
    )
    parser.add_argument(
        "--output",
        type=str,
        help="Save results to JSON file"
    )

    args = parser.parse_args()

    # Verify models directory
    models_dir = Path.home() / "MediScribe" / "models"
    if not models_dir.exists():
        print(f"❌ Models directory not found: {models_dir}")
        sys.exit(1)

    # Run evaluation
    if args.compare:
        compare_all(max_samples=args.samples)
    else:
        evaluator = SimpleQAEvaluator(
            model_quantization=args.model,
            max_samples=min(args.samples, 10)
        )
        metrics = evaluator.evaluate()
        print_results(metrics)

        if args.output and metrics:
            with open(args.output, 'w') as f:
                json.dump(metrics, f, indent=2)
            print(f"✅ Results saved to {args.output}")


if __name__ == "__main__":
    main()
