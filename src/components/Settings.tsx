import React, { useState } from 'react';
import { Settings as SettingsType } from '../types';
import { X } from 'lucide-react';

interface SettingsProps {
  settings: SettingsType;
  onClose: () => void;
  onSave: (settings: SettingsType) => void;
}

export function Settings({ settings, onClose, onSave }: SettingsProps) {
  const [localSettings, setLocalSettings] = useState(settings);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
      <div className="bg-gray-800 p-6 rounded-lg w-full max-w-md">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-bold">Settings</h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-700 rounded-lg transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              Target Size (px)
            </label>
            <input
              type="range"
              min="20"
              max="80"
              value={localSettings.targetSize}
              onChange={(e) =>
                setLocalSettings({
                  ...localSettings,
                  targetSize: Number(e.target.value),
                })
              }
              className="w-full"
            />
            <div className="text-right text-sm text-gray-400">
              {localSettings.targetSize}px
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Target Speed (ms)
            </label>
            <input
              type="range"
              min="500"
              max="2000"
              step="100"
              value={localSettings.targetSpeed}
              onChange={(e) =>
                setLocalSettings({
                  ...localSettings,
                  targetSpeed: Number(e.target.value),
                })
              }
              className="w-full"
            />
            <div className="text-right text-sm text-gray-400">
              {localSettings.targetSpeed}ms
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Game Time (seconds)
            </label>
            <input
              type="range"
              min="10"
              max="60"
              step="5"
              value={localSettings.gameTime}
              onChange={(e) =>
                setLocalSettings({
                  ...localSettings,
                  gameTime: Number(e.target.value),
                })
              }
              className="w-full"
            />
            <div className="text-right text-sm text-gray-400">
              {localSettings.gameTime}s
            </div>
          </div>
        </div>

        <div className="mt-6 flex justify-end gap-2">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-400 hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={() => onSave(localSettings)}
            className="px-4 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg text-sm font-medium transition-colors"
          >
            Save Changes
          </button>
        </div>
      </div>
    </div>
  );
}