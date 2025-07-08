import os
import csv
from dotenv import load_dotenv
import json
import re
load_dotenv()
from langchain_pinecone import PineconeVectorStore
from langchain_huggingface  import HuggingFaceEmbeddings
from langchain_core.prompts import PromptTemplate
from langchain_ollama import ChatOllama
from typing import Set, List, Dict, Any



def format_docs(docs):
    result = ""
    for doc in docs:
        result += f"- Title: {doc.metadata.get('title', 'Unknown')}\n"
        result += f"  Page: {doc.metadata.get('page_label', 'Unknown')}\n"
        result += f"  Content: {doc.page_content}\n\n"
    return result
def create_source_string(docs: Set[str]) -> str:
    """Create a numbered string of sources (title + page) from retrieved documents."""
    if not docs:
        return "No sources found."
    
    # Use a set to avoid duplicates
    sources = set()
    
    for doc in docs:
        title = doc.metadata.get("title", "Unknown")
        page = doc.metadata.get("page_label", "Unknown")
        sources.add(f"{title} (Page {page})")

    # Turn into sorted list
    source_list = list(sources)
    source_list.sort()

    # Build the string
    source_string = "Sources:\n"
    for i, src in enumerate(source_list):
        source_string += f"{i + 1}. {src}\n"

    return source_string
def run_llm(query: str, llm_model_name: str, chat_history: List[Dict[str, Any]] = []) :
    #Embeddings
    embeddings = HuggingFaceEmbeddings(model_name="intfloat/multilingual-e5-large")

    #Jenis VectorStore
    vectorstore = PineconeVectorStore(
        index_name=os.environ["INDEX_NAME"],
        embedding=embeddings,
    )
    
    #Jenis LLM
    llm = ChatOllama(model=llm_model_name, verbose=True)

    #Prompt
    template = """
    You are a Question Answering System for Akademik Universitas Tanjungpura 2025. You will be provided with a question and relevant documents.
    Your task is to answer the question based on the information in the documents context.
    If you can't answer the question based on the context but there are relevant documents in context , you should say "Silahkan Buka Pedoman Akademik Universitas Tanjungpura Secara Langsung".
    If the Question is not relevant with the Akademik Universitas Tanjungpura, say "Pertanyaan tidak relevan dengan tugas saya".
    Answer with Indonesian Language.
        <context>
        {context}
        </context>
    Question: {input}

    """
    #Jadikan template sebagai PromptTemplate
    custom_rag_prompt = PromptTemplate.from_template(template = template)

    template_rephrase = """
    You are a helpful assistant. You will be provided with a question and relevant documents.
    
    """
    retriever = vectorstore.as_retriever()
    retrieved_docs = retriever.invoke(query)
    formatted_context = format_docs(retrieved_docs)
    sources_string = create_source_string(retrieved_docs)
    
    final_prompt = custom_rag_prompt.format(context=formatted_context, input=query) 

    answer = llm.invoke(final_prompt)



    if "Pertanyaan tidak relevan dengan tugas saya" in answer.content:
        sources_string = "-"  # atau "Tidak ada sumber" atau None
    else:
        sources_string = create_source_string(retrieved_docs)
    
    result = {
        "input": query,
        "answer": answer.content,
        "sources": sources_string
    }
    return result

if __name__ == "__main__":
    query = "Bagaimana struktur kurikulum program sarjana di UNTAN mendukung evaluasi mahasiswa melalui UTS dan UAS?"
    model_name = "llama3"
    
    result = run_llm(query, model_name)
    print(result)

    