from fastapi import FastAPI, HTTPException, BackgroundTasks
import uvicorn
import sys
import os

# Add AI engine to path for import
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from ai_reasoning_engine.rag_agent import AutonomousDiagnosticAgent, DiagnosticRequest

app = FastAPI(
    title="OmniDiag-AI Core API",
    description="Enterprise Backend Orchestration for Autonomous Diagnostics",
    version="2.0.0"
)

ai_agent = AutonomousDiagnosticAgent()

@app.get("/health")
async def health_check():
    return {"status": "operational", "services": ["kafka", "qdrant", "postgres", "ai_agent"]}

@app.post("/api/v1/diagnose")
async def trigger_diagnosis(request: DiagnosticRequest):
    """
    Triggers the AI reasoning engine to analyze a vehicle fault 
    based on live telemetry streams.
    """
    try:
        response = ai_agent.analyze_fault(request)
        return {"status": "success", "data": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("api_gateway:app", host="0.0.0.0", port=8000, reload=True)
