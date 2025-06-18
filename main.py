import os
import streamlit as st
from app.agents import support_crew  # Adjust if your path is different

# Ensure LiteLLM picks up the correct config file (important for Docker)
os.environ["LITELLM_CONFIG_PATH"] = "/app/litellm.config.json"

def main():
    st.set_page_config(page_title="AI Support Assistant", page_icon="🤖")
    st.title("🤖 AI-Powered Customer Support")

    st.markdown(
        "Ask a customer support question and let the AI team help you out!"
    )

    inquiry = st.text_area("📝 Describe your issue:", height=200)

    if st.button("🔍 Get Help"):
        if inquiry.strip() == "":
            st.warning("Please enter a support inquiry.")
        else:
            with st.spinner("AI agents are working..."):
                try:
                    resolution = support_crew.run(inquiry)
                    st.success("✅ Resolution:")
                    st.write(resolution)
                except Exception as e:
                    st.error(f"❌ Something went wrong:\n\n{e}")

if __name__ == "__main__":
    main()
