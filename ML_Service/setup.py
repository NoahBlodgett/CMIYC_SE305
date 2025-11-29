from setuptools import setup, find_packages

setup(
    name="ml-service",
    version="0.1.0",
    description="Machine Learning Service for Cache Me If You Can",
    author="SE305 Team",
    packages=find_packages(),
    python_requires=">=3.8",
    install_requires=[
        "pandas>=1.3.0",
        "numpy>=1.21.0",
        "scikit-learn>=1.0.0",
        "joblib>=1.0.0",
        "fastapi>=0.68.0",
        "pydantic>=1.8.0",
        "pyarrow>=5.0.0",  # For parquet support
    ],
    extras_require={
        "dev": [
            "pytest>=6.0",
            "black>=21.0",
            "flake8>=3.9",
        ]
    },
    entry_points={
        "console_scripts": [
            "ml-preprocess=src.data.preprocessing:clean_files_and_save",
        ]
    }
)