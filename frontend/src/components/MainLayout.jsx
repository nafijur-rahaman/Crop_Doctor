import React, { useState } from 'react';
import { Home, MessageSquare, History, User, Camera } from 'lucide-react';
import HomeScreen from '../screens/HomeScreen';
import ForumScreen from '../screens/ForumScreen';
import HistoryScreen from '../screens/HistoryScreen';
import ProfileScreen from '../screens/ProfileScreen';
import CameraScreen from '../screens/CameraScreen';

export default function MainLayout() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isCameraOpen, setIsCameraOpen] = useState(false);

  const renderScreen = () => {
    switch (currentIndex) {
      case 0:
        return <HomeScreen 
          onOpenForum={() => setCurrentIndex(1)} 
          onOpenProfile={() => setCurrentIndex(3)} 
          onOpenCamera={() => setIsCameraOpen(true)}
        />;
      case 1:
        return <ForumScreen />;
      case 2:
        return <HistoryScreen />;
      case 3:
        return <ProfileScreen />;
      default:
        return <HomeScreen />;
    }
  };

  const NavItem = ({ icon: Icon, label, index }) => {
    const isSelected = currentIndex === index;
    const color = isSelected ? 'var(--primary)' : 'var(--text-secondary)';
    
    return (
      <div 
        onClick={() => setCurrentIndex(index)}
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          cursor: 'pointer',
          flex: 1,
          justifyContent: 'center',
          padding: '8px 0'
        }}
      >
        <Icon color={color} size={24} />
        <span style={{ 
          color, 
          fontSize: '10px', 
          marginTop: '4px',
          fontWeight: isSelected ? 'bold' : 'normal'
        }}>
          {label}
        </span>
      </div>
    );
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      
      {/* Main Content Area */}
      {renderScreen()}

      {/* Floating Action Button */}
      <div 
        onClick={() => setIsCameraOpen(true)}
        style={{
          position: 'absolute',
          bottom: '30px', /* Centered over the bottom bar */
          left: '50%',
          transform: 'translateX(-50%)',
          width: '60px',
          height: '60px',
          backgroundColor: 'var(--primary)',
          borderRadius: '50%',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          boxShadow: '0 4px 10px rgba(0,0,0,0.2)',
          zIndex: 10,
          cursor: 'pointer'
        }}
      >
        <Camera color="white" size={28} />
      </div>

      {/* Bottom Navigation Bar */}
      <div style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        height: '65px',
        backgroundColor: 'var(--surface)',
        display: 'flex',
        boxShadow: '0 -2px 10px rgba(0,0,0,0.05)',
        zIndex: 5,
        paddingBottom: 'max(env(safe-area-inset-bottom), 0px)'
      }}>
        <div style={{ display: 'flex', flex: 1 }}>
          <NavItem icon={Home} label="Home" index={0} />
          <NavItem icon={MessageSquare} label="Forum" index={1} />
        </div>
        
        {/* Spacer for FAB */}
        <div style={{ width: '80px' }} />
        
        <div style={{ display: 'flex', flex: 1 }}>
          <NavItem icon={History} label="History" index={2} />
          <NavItem icon={User} label="Profile" index={3} />
        </div>
      </div>

      {/* Full Screen Camera Overlay */}
      {isCameraOpen && (
        <CameraScreen onClose={() => setIsCameraOpen(false)} />
      )}
    </div>
  );
}
