import React from 'react';
import { Camera, X } from 'lucide-react';

export default function CameraScreen({ onClose }) {
  return (
    <div style={{
      position: 'absolute',
      inset: 0,
      backgroundColor: '#000',
      color: '#fff',
      display: 'flex',
      flexDirection: 'column',
      zIndex: 100
    }}>
      <div style={{ padding: '20px', display: 'flex', justifyContent: 'flex-start', marginTop: '20px' }}>
        <button 
          onClick={onClose}
          style={{ 
            color: '#fff', 
            background: 'rgba(255,255,255,0.2)', 
            borderRadius: '50%', 
            width: '40px', 
            height: '40px',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center'
          }}
        >
          <X size={24} />
        </button>
      </div>

      <div style={{ flexGrow: 1, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.5)' }}>
          <Camera size={64} style={{ marginBottom: '20px', color: 'rgba(255,255,255,0.8)' }} />
          <p>Camera feed placeholder</p>
        </div>
      </div>
      
      <div style={{
        padding: '30px',
        display: 'flex',
        justifyContent: 'center'
      }}>
        <div style={{
          width: '70px',
          height: '70px',
          borderRadius: '50%',
          border: '4px solid #fff',
          backgroundColor: 'rgba(255,255,255,0.3)',
          cursor: 'pointer'
        }} />
      </div>
    </div>
  );
}
