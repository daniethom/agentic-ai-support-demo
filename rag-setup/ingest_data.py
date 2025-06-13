import os
import json
from tqdm import tqdm
import chromadb
from llama_index.core import Document, VectorStoreIndex, Settings
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core.storage.storage_context import StorageContext
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
# --- New: Import Ollama ---
from llama_index.llms.ollama import Ollama

# --- Configuration ---
DATA_FILE = os.path.join(os.path.dirname(__file__), 'data', 'product_faqs.json')
EMBEDDING_MODEL_NAME = 'all-MiniLM-L6-v2'
CHROMA_DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'chroma_db')

# --- Load Data (Unchanged) ---
def load_data(filepath):
    try:
        with open(filepath, 'r') as f:
            raw_data = json.load(f)
        print(f"Loaded {len(raw_data)} raw documents from {filepath}")
        documents = []
        for item in tqdm(raw_data, desc="Preparing LlamaIndex Documents"):
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
    print("--- Starting Data Ingestion for ChromaDB ---")
    documents = load_data(DATA_FILE)

    print(f"Initializing ChromaDB at: {CHROMA_DB_PATH}")
    db = chromadb.PersistentClient(path=CHROMA_DB_PATH)
    chroma_collection = db.get_or_create_collection("support_faqs")
    vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
    storage_context = StorageContext.from_defaults(vector_store=vector_store)

    print(f"Loading embedding model: {EMBEDDING_MODEL_NAME}")
    Settings.embed_model = HuggingFaceEmbedding(model_name=EMBEDDING_MODEL_NAME)
    # --- New: Use Ollama for the LLM setting ---
    # Make sure Ollama is running on your machine
    Settings.llm = Ollama(model="llama3", request_timeout=120.0) # Increased timeout to 120 seconds
    Settings.chunk_size = 512

    print("Creating VectorStoreIndex...")
    index = VectorStoreIndex.from_documents(
        documents,
        storage_context=storage_context,
        show_progress=True
    )
    print("--- Data ingestion into ChromaDB complete. ---")

    print("\nPerforming a sample query with local LLM to verify...")
    query_engine = index.as_query_engine(similarity_top_k=2)
    response = query_engine.query("my internet is not working")
    
    print(f"\nQuery: 'my internet is not working'")
    print(f"\nGenerated Response: {response}")
    
    if response.source_nodes:
        print("\n--- Retrieved Source Nodes ---")
        for i, source_node in enumerate(response.source_nodes):
            print(f"Source {i+1} (Score: {source_node.score:.4f}):")
            print(f"  Title: {source_node.node.metadata.get('title')}")
            print(f"  Content: {source_node.node.text[:100]}...") # Print first 100 chars
        print("--------------------------")
    else:
        print("No relevant nodes found.")


if __name__ == "__main__":
    ingest_data()