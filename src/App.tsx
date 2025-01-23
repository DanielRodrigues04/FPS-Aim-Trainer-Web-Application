import React, { useState, useEffect, useRef } from 'react';
import { Target, Settings, Stats } from './components';
import { Auth } from './components/Auth';
import { useAuth } from './contexts/AuthContext';
import { Settings as SettingsType, GameState } from './types';
import { Timer, Settings as SettingsIcon, Activity, LogOut } from 'lucide-react';
import { supabase } from './lib/supabase';

const DEFAULT_SETTINGS: SettingsType = {
  targetSize: 40,
  targetSpeed: 1000,
  gameTime: 30,
};

function App() {
  const { user, signOut } = useAuth();
  const [settings, setSettings] = useState<SettingsType>(DEFAULT_SETTINGS);
  const [gameState, setGameState] = useState<GameState>('idle');
  const [score, setScore] = useState(0);
  const [misses, setMisses] = useState(0);
  const [timeLeft, setTimeLeft] = useState(settings.gameTime);
  const [showSettings, setShowSettings] = useState(false);
  const targetRef = useRef<{ moveTarget: () => void } | null>(null);

  useEffect(() => {
    if (user) {
      loadUserSettings();
    }
  }, [user]);

  const loadUserSettings = async () => {
    const { data, error } = await supabase
      .from('user_settings')
      .select('*')
      .eq('profile_id', user!.id)
      .single();

    if (!error && data) {
      setSettings({
        targetSize: data.target_size,
        targetSpeed: data.target_speed,
        gameTime: data.game_time,
      });
      setTimeLeft(data.game_time);
    }
  };

  const saveGameSession = async () => {
    if (!user) return;

    const accuracy = score + misses === 0 ? 0 : (score / (score + misses)) * 100;

    await supabase.from('game_sessions').insert({
      profile_id: user.id,
      score,
      misses,
      accuracy,
      target_size: settings.targetSize,
      target_speed: settings.targetSpeed,
      game_time: settings.gameTime,
    });
  };

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setMisses(0);
    setTimeLeft(settings.gameTime);
  };

  const handleTargetClick = () => {
    if (gameState === 'playing') {
      setScore(prev => prev + 1);
    }
  };

  const handleMiss = () => {
    if (gameState === 'playing') {
      setMisses(prev => prev + 1);
      // Move target to new position on miss
      targetRef.current?.moveTarget();
    }
  };

  useEffect(() => {
    let timer: number;
    if (gameState === 'playing' && timeLeft > 0) {
      timer = window.setInterval(() => {
        setTimeLeft(prev => {
          if (prev <= 1) {
            setGameState('ended');
            saveGameSession();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [gameState, timeLeft]);

  if (!user) {
    return <Auth />;
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      {/* Header */}
      <header className="bg-gray-800 p-4">
        <div className="container mx-auto flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Activity className="w-6 h-6 text-blue-400" />
            <h1 className="text-xl font-bold">FPS Aim Trainer</h1>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowSettings(!showSettings)}
              className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
            >
              <SettingsIcon className="w-6 h-6" />
            </button>
            <button
              onClick={signOut}
              className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
            >
              <LogOut className="w-6 h-6" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto p-4">
        {/* Game Stats */}
        <div className="flex justify-between items-center mb-4">
          <div className="flex gap-4">
            <Stats label="Score" value={score} />
            <Stats label="Misses" value={misses} />
            <Stats label="Accuracy" value={`${score + misses === 0 ? 0 : Math.round((score / (score + misses)) * 100)}%`} />
          </div>
          <div className="flex items-center gap-2">
            <Timer className="w-5 h-5" />
            <span className="text-xl font-mono">{timeLeft}s</span>
          </div>
        </div>

        {/* Game Area */}
        <div 
          data-game-area
          className="relative bg-gray-800 rounded-lg overflow-hidden cursor-crosshair"
          style={{ height: 'calc(100vh - 240px)' }}
          onClick={handleMiss}
        >
          {gameState === 'idle' && (
            <div className="absolute inset-0 flex items-center justify-center">
              <button
                onClick={startGame}
                className="px-6 py-3 bg-blue-500 hover:bg-blue-600 rounded-lg font-semibold transition-colors"
              >
                Start Game
              </button>
            </div>
          )}
          
          {gameState === 'ended' && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/50 backdrop-blur-sm">
              <h2 className="text-3xl font-bold mb-4">Game Over!</h2>
              <p className="text-xl mb-6">Final Score: {score}</p>
              <button
                onClick={startGame}
                className="px-6 py-3 bg-blue-500 hover:bg-blue-600 rounded-lg font-semibold transition-colors"
              >
                Play Again
              </button>
            </div>
          )}

          {gameState === 'playing' && (
            <Target
              ref={targetRef}
              size={settings.targetSize}
              speed={settings.targetSpeed}
              onClick={handleTargetClick}
            />
          )}
        </div>
      </main>

      {/* Settings Modal */}
      {showSettings && (
        <Settings
          settings={settings}
          onClose={() => setShowSettings(false)}
          onSave={async (newSettings) => {
            if (user) {
              await supabase
                .from('user_settings')
                .update({
                  target_size: newSettings.targetSize,
                  target_speed: newSettings.targetSpeed,
                  game_time: newSettings.gameTime,
                })
                .eq('profile_id', user.id);
            }
            setSettings(newSettings);
            setShowSettings(false);
          }}
        />
      )}
    </div>
  );
}

export default App;
