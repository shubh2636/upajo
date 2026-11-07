#!/usr/bin/env python3
"""
Upajo (उपजो) - Plant Disease Detection Model Training & TFLite Quantization Script
Fine-tunes MobileNetV3-Small on PlantVillage crop pathology dataset for on-device inference (<5 MB).

Target Classes (10 classes for key Indian staple crops):
1. Potato___Early_blight
2. Potato___Late_blight
3. Potato___healthy
4. Tomato___Bacterial_spot
5. Tomato___Early_blight
6. Tomato___Late_blight
7. Tomato___healthy
8. Wheat___Brown_rust
9. Wheat___Yellow_rust
10. Rice___Blast
"""

import os
import sys
import json
import argparse
import numpy as np

def train_and_export(
    dataset_dir: str,
    output_dir: str = "assets/models",
    epochs: int = 15,
    batch_size: int = 32,
    img_size: int = 224,
    quantization: str = "int8"
):
    print("=" * 70)
    print(" Upajo PlantVillage MobileNetV3 TFLite Training & Export Pipeline")
    print(f" Image Size: {img_size}x{img_size} | Quantization: {quantization}")
    print("=" * 70)

    try:
        import tensorflow as tf
        from tensorflow.keras import layers, models, optimizers
        from tensorflow.keras.applications import MobileNetV3Small
    except ImportError:
        print("[ERROR] TensorFlow 2.x is required. Install via: pip install tensorflow")
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)

    print(f"\n[Step 1/5] Loading and augmenting training dataset from: {dataset_dir}...")
    
    # 1. Dataset loading with 80/20 train/validation split
    train_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir,
        validation_split=0.2,
        subset="training",
        seed=42,
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="categorical",
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir,
        validation_split=0.2,
        subset="validation",
        seed=42,
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="categorical",
    )

    class_names = train_ds.class_names
    num_classes = len(class_names)
    print(f"[Step 1/5] Detected {num_classes} classes: {class_names}")

    # Export labels.txt
    labels_path = os.path.join(output_dir, "labels.txt")
    with open(labels_path, "w", encoding="utf-8") as f:
        for name in class_names:
            f.write(f"{name}\n")
    print(f"[Step 1/5] Saved class labels to: {labels_path}")

    # Prefetch and cache for hardware acceleration
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

    # 2. Data Augmentation Layer (Rotation, Zoom, Flip for rural field variance)
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.2),
        layers.RandomZoom(0.15),
        layers.RandomContrast(0.2),
    ], name="data_augmentation")

    # 3. Base MobileNetV3-Small Transfer Learning Architecture
    print("\n[Step 2/5] Building MobileNetV3-Small architecture with pre-trained ImageNet weights...")
    base_model = MobileNetV3Small(
        input_shape=(img_size, img_size, 3),
        include_top=False,
        weights="imagenet",
        pooling="avg",
        minimalistic=False,
    )
    base_model.trainable = False  # Freeze base feature extractor initially

    inputs = layers.Input(shape=(img_size, img_size, 3), name="input_tensor")
    x = data_augmentation(inputs)
    x = layers.Rescaling(1.0 / 255.0)(x)
    x = base_model(x, training=False)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="prediction_probabilities")(x)

    model = models.Model(inputs, outputs, name="Upajo_PlantVillage_MobileNetV3")

    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-3),
        loss="categorical_crossentropy",
        metrics=["accuracy", tf.keras.metrics.TopKCategoricalAccuracy(k=2, name="top_2_accuracy")],
    )
    model.summary()

    # 4. Phase 1: Warmup Training of Classification Head
    print("\n[Step 3/5] Phase 1 Training: Feature head warmup (5 epochs)...")
    model.fit(train_ds, validation_data=val_ds, epochs=5)

    # 5. Phase 2: Fine-Tuning Top Layers of MobileNetV3
    print("\n[Step 4/5] Phase 2 Fine-Tuning: Unfreezing top 30 layers with reduced learning rate...")
    base_model.trainable = True
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-4),
        loss="categorical_crossentropy",
        metrics=["accuracy", tf.keras.metrics.TopKCategoricalAccuracy(k=2, name="top_2_accuracy")],
    )

    remaining_epochs = max(1, epochs - 5)
    model.fit(train_ds, validation_data=val_ds, epochs=remaining_epochs)

    # 6. Evaluation
    val_loss, val_acc, val_top2 = model.evaluate(val_ds)
    print(f"\n[Validation Results] Top-1 Accuracy: {val_acc * 100:.2f}% | Top-2 Accuracy: {val_top2 * 100:.2f}%")

    # 7. Step 5/5: Post-Training Quantization to TFLite
    print(f"\n[Step 5/5] Quantizing model with {quantization.upper()} quantization for mobile budget phones...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    if quantization == "int8":
        def representative_data_gen():
            for images, _ in val_ds.take(100):
                for i in range(min(5, images.shape[0])):
                    yield [tf.expand_dims(images[i], 0)]

        converter.representative_dataset = representative_data_gen
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.uint8
        converter.inference_output_type = tf.uint8

    tflite_model = converter.convert()

    tflite_path = os.path.join(output_dir, "plantvillage_mobilenet_v3.tflite")
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)

    size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
    print(f"\n[SUCCESS] Exported Quantized TFLite Model: {tflite_path}")
    print(f"Model File Size: {size_mb:.2f} MB (Optimized for 2 GB RAM Android devices)")
    print("=" * 70)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upajo PlantVillage TFLite Training Pipeline")
    parser.add_argument("--dataset_dir", type=str, default="data/plantvillage", help="Directory path to PlantVillage images")
    parser.add_argument("--output_dir", type=str, default="assets/models", help="Export target directory")
    parser.add_argument("--epochs", type=int, default=15, help="Total training epochs")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--quantization", type=str, default="int8", choices=["int8", "fp16", "none"])
    args = parser.parse_args()

    # Note: When running in local development without full raw PlantVillage dataset directory,
    # dummy verification run can be tested by providing local image folder.
    if os.path.exists(args.dataset_dir):
        train_and_export(
            dataset_dir=args.dataset_dir,
            output_dir=args.output_dir,
            epochs=args.epochs,
            batch_size=args.batch_size,
            quantization=args.quantization,
        )
    else:
        print(f"[INFO] Dataset directory '{args.dataset_dir}' not found locally. Script is pre-configured and ready for training cluster.")
