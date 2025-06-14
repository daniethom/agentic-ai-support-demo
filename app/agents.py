# app/agents.py

import os
from crewai import Agent, Task, Crew

# Import your tools
from app.tools import (
    KnowledgeBaseTool,
    CustomerDetailsTool,
    TroubleshootingTool,
    TicketingTool,
    DeviceRebootTool,
    TavilySearchTool,
)

# Explicitly define the LiteLLM model name for Ollama
OLLAMA_MODEL_NAME = "ollama/llama3"

class SupportCrew:
    def __init__(self):
        # Initialize tools
        knowledge_tool = KnowledgeBaseTool()
        customer_tool = CustomerDetailsTool()
        troubleshoot_tool = TroubleshootingTool()
        ticket_tool = TicketingTool()
        reboot_tool = DeviceRebootTool()
        search_tool = TavilySearchTool()

        # Define agents using the local LLaMA3 model via LiteLLM
        self.tier_1 = Agent(
            role="Tier 1 Support Analyst",
            goal="Resolve basic customer issues using documentation and known solutions",
            backstory="You are the first point of contact for support. Use available tools to help users resolve common issues efficiently.",
            tools=[knowledge_tool, customer_tool, troubleshoot_tool],
            allow_delegation=True,
            verbose=True,
            model=OLLAMA_MODEL_NAME,
        )

        self.tier_2 = Agent(
            role="Tier 2 Support Specialist",
            goal="Handle escalated issues and create support tickets when necessary",
            backstory="You handle complex support cases passed on by Tier 1. You may create tickets or reboot devices as needed.",
            tools=[ticket_tool, reboot_tool],
            allow_delegation=False,
            verbose=True,
            model=OLLAMA_MODEL_NAME,
        )

        self.researcher = Agent(
            role="Support Research Assistant",
            goal="Search the web for relevant information about the customer issue",
            backstory="You assist support agents by looking for useful solutions or context from the internet.",
            tools=[search_tool],
            allow_delegation=False,
            verbose=True,
            model=OLLAMA_MODEL_NAME,
        )

    def run(self, inquiry: str) -> str:
        # Define tasks
        task_tier1 = Task(
            description=f"Triage and try to resolve the customer's issue: {inquiry}",
            expected_output="Clear and accurate explanation or resolution steps for the user.",
            agent=self.tier_1,
        )

        task_research = Task(
            description=f"Search online to help resolve this support question: {inquiry}",
            expected_output="Relevant context or articles that can assist in resolving the issue.",
            agent=self.researcher,
        )

        task_tier2 = Task(
            description=(
                f"If Tier 1 is unable to fully resolve the issue, provide next steps or escalate. "
                f"Issue details: {inquiry}"
            ),
            expected_output="Clear decision on whether to escalate or resolve, and ticket creation if needed.",
            agent=self.tier_2,
            depends_on=[task_tier1, task_research],
        )

        # Create the crew and assign agents and tasks
        self.crew = Crew(
            agents=[self.tier_1, self.tier_2, self.researcher],
            tasks=[task_tier1, task_research, task_tier2],
            verbose=True,
        )

        # Execute the workflow and return the resolution
        return self.crew.kickoff()
