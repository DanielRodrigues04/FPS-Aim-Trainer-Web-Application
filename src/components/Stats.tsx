import React from 'react';

interface StatsProps {
  label: string;
  value: string | number;
}

export function Stats({ label, value }: StatsProps) {
  return (
    <div className="bg-gray-800 px-4 py-2 rounded-lg">
      <div className="text-sm text-gray-400">{label}</div>
      <div className="text-xl font-semibold">{value}</div>
    </div>
  );
}