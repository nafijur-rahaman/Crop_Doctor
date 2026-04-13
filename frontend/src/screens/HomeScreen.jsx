import React from 'react';
import { 
  Sun, Droplets, Wind, Camera, ChevronRight, 
  Calculator, Leaf, MessageCircleQuestion 
} from 'lucide-react';
import FarmCard from '../components/FarmCard';
import ToolIcon from '../components/ToolIcon';

export default function HomeScreen({ onOpenForum, onOpenProfile, onOpenCamera }) {
  return (
    <div style={{
      padding: '0 20px',
      overflowY: 'auto',
      flexGrow: 1,
      paddingBottom: '100px' // Space for bottom nav
    }}>
      {/* Header */}
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        marginTop: '60px'
      }}>
        <div>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Good Morning,
          </p>
          <h2 style={{ fontSize: '26px', color: 'var(--text-primary)' }}>
            Tanjid Nafis
          </h2>
        </div>
        <div 
          onClick={onOpenProfile}
          style={{
            width: '50px',
            height: '50px',
            backgroundColor: 'var(--primary)',
            borderRadius: '50%',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            color: 'var(--text-light)',
            fontWeight: 'bold',
            cursor: 'pointer'
          }}
        >
          TN
        </div>
      </div>

      {/* Weather Card */}
      <div style={{
        marginTop: '25px',
        padding: '18px',
        backgroundColor: 'var(--surface)',
        borderRadius: '22px',
        boxShadow: 'var(--shadow-default)',
        display: 'flex',
        alignItems: 'center'
      }}>
        <Sun color="orange" size={40} />
        <div style={{ marginLeft: '15px', flexGrow: 1 }}>
          <h3 style={{ fontSize: '18px', color: 'var(--text-primary)', marginBottom: '4px' }}>
            28 C, Sunny
          </h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>
            Perfect for spraying
          </p>
        </div>
        <Droplets size={16} color="#2196f3" />
        <span style={{ fontSize: '12px', marginLeft: '4px', marginRight: '10px' }}>45%</span>
        <Wind size={16} color="grey" />
        <span style={{ fontSize: '12px', marginLeft: '4px' }}>12km/h</span>
      </div>

      {/* Scan Card Hero */}
      <div 
        onClick={onOpenCamera}
        style={{
          marginTop: '25px',
          padding: '24px',
          background: 'linear-gradient(135deg, var(--primary), var(--primary-dark))',
          borderRadius: '30px',
          boxShadow: 'var(--shadow-highlight)',
          display: 'flex',
          alignItems: 'center',
          cursor: 'pointer',
          color: 'var(--text-light)'
        }}
      >
        <div style={{ flexGrow: 1 }}>
          <Camera color="var(--text-light)" size={40} />
          <h3 style={{ fontSize: '24px', marginTop: '15px', marginBottom: '4px' }}>
            Scan Crop
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: '14px' }}>
            Instantly detect diseases using AI.
          </p>
        </div>
        <div style={{
          width: '50px',
          height: '50px',
          backgroundColor: 'rgba(255,255,255,0.24)',
          borderRadius: '50%',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center'
        }}>
          <ChevronRight color="var(--text-light)" size={20} style={{ marginLeft: '4px'}} />
        </div>
      </div>

      {/* Quick Tools */}
      <div style={{ marginTop: '30px' }}>
        <p style={{
          fontWeight: 'bold',
          color: 'var(--text-secondary)',
          fontSize: '12px',
          letterSpacing: '1.1px',
          marginBottom: '15px'
        }}>
          QUICK TOOLS
        </p>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <ToolIcon 
            icon={Calculator} 
            label="Fertilizer Calc" 
            color="#2196f3" 
            onTap={() => alert('Fertilizer calculator will be updated later.')} 
          />
          <ToolIcon 
            icon={Leaf} 
            label="Seed Guide" 
            color="#9c27b0" 
            onTap={() => alert('Seed guide will be updated later.')} 
          />
          <ToolIcon 
            icon={MessageCircleQuestion} 
            label="Expert Chat" 
            color="#ff9800" 
            onTap={onOpenForum} 
          />
        </div>
      </div>

      {/* My Farm */}
      <div style={{ marginTop: '30px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
          <h2 style={{ fontSize: '20px', color: 'var(--text-primary)' }}>My Farm</h2>
          <button style={{ color: 'var(--primary)', fontWeight: 'bold' }} onClick={onOpenProfile}>
            Edit
          </button>
        </div>
        
        <FarmCard 
          cropName="Tomato"
          stage="Fruiting"
          healthScore={0.92}
          accentColor="#FF5252"
          onTap={onOpenForum}
        />
        <FarmCard 
          cropName="Potato"
          stage="Vegetative"
          healthScore={0.98}
          accentColor="#795548"
          onTap={onOpenForum}
        />
      </div>
    </div>
  );
}
