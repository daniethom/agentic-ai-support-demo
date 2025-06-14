# app.py

import streamlit as st
from pydantic import ValidationError
from app.agents import SupportCrew    # <-- ensure this points at your updated agents.py
from dotenv import load_dotenv
load_dotenv()

def main():
    st.set_page_config(page_title="Agentic AI Support Demo", layout="centered")
    st.title("🛠️ Agentic AI Support Demo")

    inquiry = st.text_input(
        "Describe your issue", 
        placeholder="e.g. “My router keeps dropping Wi‑Fi”"
    )

    if inquiry:
        support_crew = SupportCrew()
        try:
            with st.spinner("Our AI agents are on the case…"):
                resolution = support_crew.run(inquiry)
            st.subheader("✅ Resolution")
            st.markdown(resolution)
        except ValidationError as e:
            st.error("⚠️ Validation failed when constructing the agents:")
            # This will show you which field/tool is still wrong
            st.json(e.errors())

if __name__ == "__main__":
    main()
