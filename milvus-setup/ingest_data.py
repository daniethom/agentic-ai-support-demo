import os
import json
from sentence_transformers import SentenceTransformer
from llama_index.core import VectorStoreIndex, Document, StorageContext
from llama_index.vector_stores.chroma import ChromaVectorStore
import chromadb
from tqdm import tqdm

# --- Configuration ---
COLLECTION_NAME = "it_support_knowledge"
DATA_FILE = os.path.join(os.path.dirname(__file__), 'data', 'product_faqs.json')
EMBEDDING_MODEL_NAME = 'all-MiniLM-L6-v2'
CHROMA_PERSIST_DIR = os.path.join(os.path.dirname(__file__), 'chroma_data') # Local directory for Chroma data

# --- Initialize Embedding Model ---
print(f"Loading SentenceTransformer model: {EMBEDDING_MODEL_NAME}...")
try:
    model = SentenceTransformer(EMBEDDING_MODEL_NAME)
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading SentenceTransformer model: {e}")
    print("Please ensure your Codespace has internet access and sufficient resources.")
    exit(1)

# --- Load Data ---
def load_data(filepath):
    try:
        with open(filepath, 'r') as f:
            raw_data = json.load(f)
        print(f"Loaded {len(raw_data)} raw documents from {filepath}")
        # Convert raw JSON entries into LlamaIndex Document objects
        documents = []
        for item in raw_data:
            # Store original data in metadata, content in text
            doc = Document(
                text=item["content"],
                metadata={
                    "id": item["id"],
                    "title": item["title"],
                    "category": item["category"]
                }
            )
            documents.append(doc)
        return documents
    except FileNotFoundError:
        print(f"Error: Data file not found at {filepath}")
        exit(1)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in {filepath}")
        exit(1)

# --- Main Ingestion Logic ---
def ingest_data():
    print(f"Initializing ChromaDB client (data will be stored in '{CHROMA_PERSIST_DIR}')...")
    # Ensure the directory exists
    os.makedirs(CHROMA_PERSIST_DIR, exist_ok=True)
    db = chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)

    # Get or create the collection
    # LlamaIndex will manage embeddings via its service context
    try:
        chroma_collection = db.get_or_create_collection(COLLECTION_NAME)
        print(f"ChromaDB collection '{COLLECTION_NAME}' ready.")
    except Exception as e:
        print(f"Error getting/creating ChromaDB collection: {e}")
        print("Attempting to delete existing collection and retry.")
        try:
            db.delete_collection(COLLECTION_NAME)
            chroma_collection = db.get_or_create_collection(COLLECTION_NAME)
            print(f"ChromaDB collection '{COLLECTION_NAME}' recreated.")
        except Exception as retry_e:
            print(f"Failed to delete and recreate collection: {retry_e}")
            exit(1)

    # Set up ChromaDB as a LlamaIndex VectorStore
    vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
    storage_context = StorageContext.from_defaults(vector_store=vector_store)

    # Load documents
    documents = load_data(DATA_FILE)

    # Create LlamaIndex for ingestion (this will embed and store in Chroma)
    print("Creating VectorStoreIndex (this will embed and ingest data)...")
    # We need a ServiceContext to provide the embedding model to the index
    from llama_index.core import ServiceContext
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding
    from llama_index.llms.openai import OpenAI # Dummy LLM, not used for ingestion but required by ServiceContext

    # Initialize the embedding model directly for LlamaIndex
    embed_model_llama_index = HuggingFaceEmbedding(model_name=EMBEDDING_MODEL_NAME)
    # Create a dummy LLM as it's required by ServiceContext, but won't be used for just ingestion
    dummy_llm = OpenAI(model="gpt-3.5-turbo", api_key="sk-dummy", api_base="http://localhost:1", temperature=0.0)

    service_context = ServiceContext.from_defaults(
        llm=dummy_llm,
        embed_model=embed_model_llama_index,
        chunk_size=512 # Default chunk size
    )

    index = VectorStoreIndex.from_documents(
        documents,
        storage_context=storage_context,
        service_context=service_context,
        show_progress=True # Show progress bar for embedding
    )
    print("Data ingestion into ChromaDB complete.")

    # --- Optional: Verify data by performing a sample query ---
    print("\nPerforming a sample vector query to verify data ingestion:")
    query_engine = index.as_query_engine(similarity_top_k=1)
    query_text = "my internet is not working"
    response = query_engine.query(query_text)

    print(f"Query: '{query_text}'")
    print(f"Retrieved Node (Title): {response.source_nodes[0].node.metadata.get('title')}")
    print(f"Retrieved Node (Content): {response.source_nodes[0].node.text}")
    print(f"Similarity Score (LlamaIndex): {response.source_nodes[0].score:.4f}")
    print(f"Generated Response: {response}") # Note: This response will be generic as no actual LLM connection yet

if __name__ == "__main__":
    ingest_data()