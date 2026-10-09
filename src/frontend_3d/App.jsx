import React, { useRef, useState } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Stars } from '@react-three/drei';

/**
 * 3D ECU Network Topology Component
 * Renders the vehicle's electronic modules in a cinematic 3D space.
 * Red nodes indicate faults (e.g., Engine Control Module).
 * Green nodes indicate healthy modules.
 */

function ECUNode({ position, color, label }) {
  const mesh = useRef();
  // Cinematic slow rotation for the ECU node
  useFrame(() => (mesh.current.rotation.x = mesh.current.rotation.y += 0.01));

  return (
    <mesh position={position} ref={mesh}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color={color} wireframe />
      {/* In a full version, we map HTML text over this to show the label */}
    </mesh>
  );
}

export default function App() {
  return (
    <div style={{ width: '100vw', height: '100vh', background: '#0a0a0a' }}>
      <h1 style={{ color: 'white', position: 'absolute', top: 20, left: 20, zIndex: 10, fontFamily: 'monospace' }}>
        OmniDiag-AI: 3D Network Topology
      </h1>
      <Canvas camera={{ position: [0, 0, 10] }}>
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} />
        <Stars radius={100} depth={50} count={5000} factor={4} saturation={0} fade speed={1} />
        
        {/* Engine Control Unit - Faulty (Red) */}
        <ECUNode position={[-3, 0, 0]} color="#ff2a2a" label="ECM" />
        
        {/* Transmission Control Unit - Healthy (Green) */}
        <ECUNode position={[0, 2, -2]} color="#00ff00" label="TCM" />
        
        {/* Body Control Module - Healthy (Green) */}
        <ECUNode position={[3, 0, 0]} color="#00ff00" label="BCM" />
        
        {/* ABS Module - Healthy (Green) */}
        <ECUNode position={[0, -2, -2]} color="#00ff00" label="ABS" />
        
        <OrbitControls enableZoom={true} />
      </Canvas>
    </div>
  );
}
