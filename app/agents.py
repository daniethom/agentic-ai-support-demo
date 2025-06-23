import os
from crewai import Crew, Agent, Task
from app.tools import (
    KnowledgeBaseTool,
    CustomerDetailsTool,
    TroubleshootingTool,
    TicketingTool,
    DeviceRebootTool,
    TavilySearchTool
)

# CRITICAL: Set the config path for LiteLLM before you initialize any agent.
# This ensures that LiteLLM knows where to find your model definitions.
# We assume this script is run from the root of the project where litellm.config.json is located.
os.environ["LITELLM_CONFIG_PATH"] = "litellm.config.json"

# Define agents
customer_support_agent = Agent(
    role="Customer Support Agent",
    goal="Understand and resolve customer issues efficiently",
    backstory="You are an expert at diagnosing customer service problems and finding helpful answers from internal tools.",
    tools=[
        KnowledgeBaseTool(),
        CustomerDetailsTool(),
        TroubleshootingTool(),
        TicketingTool(),
        DeviceRebootTool(),
        TavilySearchTool()
    ],
    allow_delegation=False,
    verbose=True,
    # 👇 Use model alias configured in litellm.config.json
    llm={"model": "demo-llm"}
)

# Define task
support_task = Task(
    description="Use all available tools to answer the customer inquiry: '{input}'",
    expected_output="A helpful and accurate resolution to the customer's issue.",
    agent=customer_support_agent
)

# Define crew
support_crew = Crew(
    agents=[customer_support_agent],
    tasks=[support_task],
    verbose=True  # Optional: show more internal logs
)

# Optional helper for main.py
def run(inquiry: str) -> str:
    return support_crew.kickoff(inputs={"input": inquiry})