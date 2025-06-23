from app import agents

test_inquiry = "My internet keeps disconnecting every few hours. Can you help?"
response = agents.run(test_inquiry)
print("\nFinal Response:\n", response)
