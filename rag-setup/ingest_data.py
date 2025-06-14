# In agentic-ai-support-demo/rag-setup/ingest_data.py

import os
import json
import weaviate # Use the v4 client
from llama_index.core import Document, VectorStoreIndex, Settings
from llama_index.vector_stores.weaviate import WeaviateVectorStore
from llama_index.embeddings.huggingface import HuggingFaceEmbedding

def ingest_data_weaviate_v4():
    """
    Loads data and ingests it into a running Weaviate instance using the v4 client.
    """
    print("--- Starting Data Ingestion for Weaviate (v4 Client) ---")

    # --- Configuration ---
    DATA_FILE = os.path.join(os.path.dirname(__file__), 'data', 'product_faqs.json')
    EMBEDDING_MODEL_NAME = 'all-MiniLM-L6-v2'
    WEAVIATE_INDEX_NAME = "SupportFAQs"

    # --- Load Data ---
    try:
        with open(DATA_FILE, 'r') as f:
            documents = [Document(text=item["content"], metadata={"id": item["id"], "title": item["title"], "category": item["category"]}) for item in json.load(f)]
        print(f"Loaded {len(documents)} raw documents.")
    except Exception as e:
        print(f"Error loading data: {e}")
        exit(1)

    # --- Setup and Ingestion ---
    print("Connecting to Weaviate instance using the v4 client...")
    # Use the v4 connection method
    client = weaviate.connect_to_local()
    
    # Check if the collection already exists and delete it for a clean run
    if client.collections.exists(WEAVIATE_INDEX_NAME):
        client.collections.delete(WEAVIATE_INDEX_NAME)
        print(f"Deleted existing Weaviate collection: {WEAVIATE_INDEX_NAME}")

    vector_store = WeaviateVectorStore(weaviate_client=client, index_name=WEAVIATE_INDEX_NAME)

    print(f"Loading embedding model: {EMBEDDING_MODEL_NAME}")
    Settings.embed_model = HuggingFaceEmbedding(model_name=EMBEDDING_MODEL_NAME)
    Settings.llm = None

    print(f"Creating and storing index '{WEAVIATE_INDEX_NAME}' in Weaviate...")
    VectorStoreIndex.from_documents(
        documents,
        vector_store=vector_store,
        show_progress=True
    )
    print("\n--- ✅ Success! Data ingestion into Weaviate is complete. ---")
    client.close() # Close the connection

if __name__ == "__main__":
    ingest_data_weaviate_v4()