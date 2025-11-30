import pandas as pd
import numpy as np

from sklearn.cluster import MiniBatchKMeans


def build_clusters(
    inputPath: str = "ML_Service/data/processed/all_meals_embeddings.parquet",
    outputPath: str = "ML_Service/data/processed/all_meals_with_clusters.parquet",
    k: int = 32):
    
    df = pd.read_parquet(inputPath)

    # grab the embedding columns and load it into a numpy array
    emb_cols = [col for col in df.columns if col.startswith("emb")]
    X = df[emb_cols].values.astype(np.float32)


    kmeans = MiniBatchKMeans(
        n_clusters=k, # number of clusters
        batch_size=4096, # chunks of 4096 samples
        n_init=10, # runs 10 times and picks the best
        max_iter=200, # enough to converge
        random_state=42, 
        verbose=1 
    )
    cluster_ids = kmeans.fit_predict(X) # clustering model

    df["cluster_id"] = cluster_ids.astype(np.int32)

    cluster_counts = df["cluster_id"].value_counts().sort_index()
    print(cluster_counts)

    df.to_parquet(outputPath, index=False)

if __name__ == "__main__":
    build_clusters()
