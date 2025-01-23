import React, { useState, useEffect, useCallback, forwardRef, useImperativeHandle } from 'react';

interface TargetProps {
  size: number;
  speed: number;
  onClick: () => void;
}

export const Target = forwardRef<{ moveTarget: () => void }, TargetProps>(
  ({ size, speed, onClick }, ref) => {
    const [position, setPosition] = useState({ x: 0, y: 0 });

    const moveTarget = useCallback(() => {
      const container = document.querySelector('[data-game-area]');
      if (container) {
        const maxX = container.clientWidth - size;
        const maxY = container.clientHeight - size;
        
        const newX = Math.floor(Math.random() * maxX);
        const newY = Math.floor(Math.random() * maxY);
        
        setPosition({ x: newX, y: newY });
      }
    }, [size]);

    // Expose moveTarget function to parent component
    useImperativeHandle(ref, () => ({
      moveTarget
    }));

    // Initial position
    useEffect(() => {
      moveTarget();
    }, [moveTarget]);

    const handleClick = (e: React.MouseEvent) => {
      e.stopPropagation();
      onClick();
      moveTarget();
    };

    return (
      <div
        className="absolute cursor-pointer"
        style={{
          width: size,
          height: size,
          left: position.x,
          top: position.y,
          transition: `left ${speed * 0.001}s, top ${speed * 0.001}s`,
        }}
        onClick={handleClick}
      >
        <div className="w-full h-full rounded-full bg-red-500 hover:bg-red-600 shadow-lg transform hover:scale-95 transition-all" />
      </div>
    );
  }
);

Target.displayName = 'Target';
