import os
import json
from milvus import MilvusClient, CollectionSchema, FieldSchema, DataType
from sentence_transformers import SentenceTransformer
import time
from tqdm import tqdm # For a nice progress bar

# --- Configuration ---
MILVUS_HOST = os.getenv("MILVUS_HOST", "localhost")
MILVUS_PORT = os.getenv("MILVUS_PORT", "19530")
MILVUS_URI = f"{MILVUS_HOST}:{MILVUS_PORT}"
COLLECTION_NAME = "it_support_knowledge"
DATA_FILE = os.path.join(os.path.dirname(__file__), 'data', 'product_faqs.json')
EMBEDDING_MODEL_NAME = 'all-MiniLM-L6-v2' # A good small, fast model for embeddings

# --- Initialize Embedding Model ---
print(f"Loading SentenceTransformer model: {EMBEDDING_MODEL_NAME}...")
# This model will download if not available locally in the Codespace.
# It might take a moment.
try:
    model = SentenceTransformer(EMBEDDING_MODEL_NAME)
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading SentenceTransformer model: {e}")
    print("Please ensure your Codespace has internet access and sufficient resources.")
    exit(1)


# --- Milvus Client Initialization ---
def get_milvus_client():
    for i in range(10): # Retry connection
        try:
            client = MilvusClient(uri=MILVUS_URI)
            # Check if Milvus is ready by trying a simple operation
            client.list_collections()
            print(f"Connected to Milvus at {MILVUS_URI}")
            return client
        except Exception as e:
            print(f"Attempt {i+1}: Could not connect to Milvus at {MILVUS_URI}. Retrying in 5 seconds...")
            print(f"Error: {e}")
            time.sleep(5)
    print("Failed to connect to Milvus after multiple retries. Exiting.")
    exit(1)

# --- Load Data ---
def load_data(filepath):
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        print(f"Loaded {len(data)} documents from {filepath}")
        return data
    except FileNotFoundError:
        print(f"Error: Data file not found at {filepath}")
        exit(1)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in {filepath}")
        exit(1)

# --- Create Collection Schema ---
def create_collection_schema():
    # Define the fields in your collection
    fields = [
        FieldSchema(name="id", dtype=DataType.VARCHAR, max_length=128, is_primary=True),
        FieldSchema(name="title", dtype=DataType.VARCHAR, max_length=256),
        FieldSchema(name="content", dtype=DataType.TEXT),
        FieldSchema(name="category", dtype=DataType.VARCHAR, max_length=128),
        FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=model.get_sentence_embedding_dimension()) # Dimension from our model
    ]
    # Define the collection schema
    schema = CollectionSchema(fields=fields, enable_dynamic_field=True)
    return schema

# --- Main Ingestion Logic ---
def ingest_data():
    client = get_milvus_client()

    # Drop collection if it already exists for a clean demo run
    if client.has_collection(collection_name=COLLECTION_NAME):
        print(f"Collection '{COLLECTION_NAME}' already exists. Dropping it...")
        client.drop_collection(collection_name=COLLECTION_NAME)
        print("Collection dropped.")

    # Create the collection
    schema = create_collection_schema()
    print(f"Creating collection '{COLLECTION_NAME}'...")
    client.create_collection(
        collection_name=COLLECTION_NAME,
        schema=schema,
        # Set up the index for efficient vector search
        index_params={
            "field_name": "embedding",
            "index_type": "FLAT", # Simple index for small datasets, faster for demo
            "metric_type": "L2"    # Euclidean distance
        }
    )
    print(f"Collection '{COLLECTION_NAME}' created.")

    # Load data from JSON file
    documents = load_data(DATA_FILE)

    # Prepare data for insertion
    entities = []
    print(f"Generating embeddings and preparing data for insertion into '{COLLECTION_NAME}'...")
    for doc in tqdm(documents, desc="Embedding documents"):
        # Generate embedding for the content
        embedding = model.encode(doc["content"]).tolist() # Convert numpy array to list
        entities.append({
            "id": doc["id"],
            "title": doc["title"],
            "content": doc["content"],
            "category": doc["category"],
            "embedding": embedding
        })

    # Insert data into Milvus
    print(f"Inserting {len(entities)} entities...")
    insert_result = client.insert(
        collection_name=COLLECTION_NAME,
        data=entities
    )
    print(f"Data insertion complete. Inserted IDs: {insert_result['insert_ids']}")
    print(f"Total entities in collection: {client.get_collection_stats(COLLECTION_NAME)['row_count']}")

    # --- Optional: Verify data by performing a sample search ---
    print("\nPerforming a sample vector search to verify data ingestion:")
    query_text = "my internet is not working"
    query_embedding = model.encode(query_text).tolist()

    search_results = client.search(
        collection_name=COLLECTION_NAME,
        data=[query_embedding],
        output_fields=["title", "content", "category"],
        limit=1 # Retrieve top 1 most similar result
    )

    if search_results and search_results[0]['hits']:
        print(f"Query: '{query_text}'")
        print(f"Found match: {search_results[0]['hits'][0]['entity']['title']}")
        print(f"Content: {search_results[0]['hits'][0]['entity']['content']}")
        print(f"Similarity Score: {search_results[0]['hits'][0]['score']:.4f}")
    else:
        print("No results found for sample query.")

    client.close()
    print("Milvus client closed.")

if __name__ == "__main__":
    ingest_data()