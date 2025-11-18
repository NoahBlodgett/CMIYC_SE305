import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import TruncatedSVD
from sklearn.preprocessing import Normalizer

def buildEmbeddings( inputPath: str = "ML_Service/data/processed/all_meals_clean.parquet", 
                     outputPath: str = "ML_Service/data/processed/all_meals_embeddings.parquet"):
    
    df = pd.read_parquet(inputPath)
    print('loaded data:', df.shape)
    print(df.head())

    # if name missing replace with empty string so model still works and treat different capitailzed words the same
    texts = (df['name'].fillna('').astype(str).str.lower())

    vectorizer = TfidfVectorizer(
        min_df=5, #drop words that appear less than 5 times to reduce noise
        max_df=0.5, #drop words that appear more than 50% of the time. to common maybe something like salt
        max_features=50000, #cap to save memory
        ngram_range=(1,2) # helps differientiate chicken and chicken salad
    )
    
    # vectorizes learns vocab and converts to numbers
    print("Fitting TF-IDF vectorizer...")
    x_tfidf = vectorizer.fit_transform(texts)
    print("TF-IDF matrix shape:", x_tfidf.shape)

    # represents each recipe in 128D 
    svd = TruncatedSVD(n_components=128, random_state=42)

    print("Fitting TruncatedSVD...")
    x_svd = svd.fit_transform(x_tfidf)  # shape: (n_recipes, 128)
    print("SVD output shape:", x_svd.shape)

    # normalize
    normalizer = Normalizer(copy=False)
    x_emb = normalizer.fit_transform(x_svd)

    # creates rows, casts to float 32 to save memory
    emb_cols = [f"emb{i}" for i in range(x_emb.shape[1])]
    emb_df = pd.DataFrame(x_emb.astype(np.float32), columns=emb_cols)

    base_cols = [
        "recipe_id",
        "name",
        "meal_type",
        "per_serving_kcal",
        "protein_g",
        "carbs_g",
        "fat_g",
    ]

    # merges meta data back in and has the new embedded data added to the end
    out_df = pd.concat([df[base_cols].reset_index(drop=True), emb_df.reset_index(drop=True)], axis=1)

    out_df.to_parquet(outputPath, index=False)
    print(f"Saved embeddings to {outputPath}")

if __name__ == "__main__":
    buildEmbeddings()





