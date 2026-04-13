import React from 'react';
import { Sprout } from 'lucide-react';

export default function FarmCard({ cropName, stage, healthScore, accentColor, onTap }) {
  const healthPercentage = Math.round(healthScore * 100);
  
  return (
    <div 
      onClick={onTap}
      style={{
        marginBottom: '14px',
        padding: '18px',
        backgroundColor: 'var(--surface)',
        borderRadius: '22px',
        boxShadow: 'var(--shadow-default)',
        display: 'flex',
        alignItems: 'center',
        cursor: 'pointer',
      }}
    >
      <div 
        style={{
          width: '52px',
          height: '52px',
          backgroundColor: `${accentColor}1A`, // 10-12% opacity approx
          borderRadius: '12px',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          flexShrink: 0
        }}
      >
        <Sprout color={accentColor} size={28} />
      </div>
      
      <div style={{ marginLeft: '14px', flexGrow: 1 }}>
        <h3 style={{ 
          fontSize: '17px', 
          fontWeight: 'bold', 
          color: 'var(--text-primary)',
          marginBottom: '4px' 
        }}>
          {cropName}
        </h3>
        <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginBottom: '12px' }}>
          Growth stage: {stage}
        </p>
        
        <div style={{ 
          height: '8px', 
          backgroundColor: '#E9EEF1', 
          borderRadius: '999px',
          overflow: 'hidden' 
        }}>
          <div style={{
            height: '100%',
            width: `${healthPercentage}%`,
            backgroundColor: accentColor,
            borderRadius: '999px'
          }} />
        </div>
      </div>
      
      <div style={{ 
        marginLeft: '14px', 
        fontSize: '18px', 
        fontWeight: 'bold', 
        color: accentColor 
      }}>
        {healthPercentage}%
      </div>
    </div>
  );
}
