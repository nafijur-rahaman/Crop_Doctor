import React from 'react';

export default function ToolIcon({ icon: Icon, label, color, onTap }) {
  return (
    <div 
      onClick={onTap}
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        cursor: 'pointer'
      }}
    >
      <div style={{
        padding: '16px',
        backgroundColor: 'var(--surface)',
        borderRadius: '22px',
        boxShadow: '0 2px 4px var(--card-shadow)',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center'
      }}>
        <Icon color={color} size={28} />
      </div>
      <div style={{ marginTop: '8px', width: '88px' }}>
        <p style={{
          textAlign: 'center',
          fontSize: '12px',
          fontWeight: 600,
          color: 'var(--text-primary)'
        }}>
          {label}
        </p>
      </div>
    </div>
  );
}
