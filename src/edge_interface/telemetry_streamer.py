import asyncio
import json
import random
import logging
from datetime import datetime, timezone

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] EDGE: %(message)s")

class VehicleTelemetryStreamer:
    """
    Simulates high-concurrency CAN FD / OBD2 telemetry ingestion.
    In a production environment, this interfaces with J2534 or SocketCAN.
    """
    def __init__(self, vin: str):
        self.vin = vin
        self.is_streaming = False

    async def read_live_data(self):
        """Simulates reading live PIDs (Parameter IDs) from the vehicle ECU."""
        return {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "vin": self.vin,
            "engine_rpm": random.randint(800, 3500),
            "vehicle_speed": random.randint(0, 120),
            "coolant_temp_c": random.randint(80, 105),
            "mass_air_flow_gs": round(random.uniform(2.0, 50.0), 2),
            "o2_sensor_volts": round(random.uniform(0.1, 0.9), 2),
            "active_dtcs": ["P0171"] if random.random() > 0.8 else []
        }

    async def start_stream(self):
        self.is_streaming = True
        logging.info(f"Started telemetry stream for VIN: {self.vin}")
        
        while self.is_streaming:
            data = await self.read_live_data()
            # In production, push to Apache Kafka here
            logging.info(f"Publishing to Kafka Topic [vehicle.telemetry]: {json.dumps(data)}")
            await asyncio.sleep(1.0)  # 1Hz refresh rate

if __name__ == "__main__":
    streamer = VehicleTelemetryStreamer(vin="WBA00000000000000")
    try:
        asyncio.run(streamer.start_stream())
    except KeyboardInterrupt:
        logging.info("Telemetry stream gracefully stopped.")
