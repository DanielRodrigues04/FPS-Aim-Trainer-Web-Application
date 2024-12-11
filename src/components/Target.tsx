import React, { useState, useEffect } from 'react';

interface TargetProps {
  size: number;
  speed: number;
  onClick: () => void;
}

export function Target({ size, speed, onClick }: TargetProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const moveTarget = () => {
    const container = document.querySelector('.game-area');
    if (container) {
      const maxX = container.clientWidth - size;
      const maxY = container.clientHeight - size;
      setPosition({
        x: Math.random() * maxX,
        y: Math.random() * maxY,
      });
    }
  };

  useEffect(() => {
    moveTarget(); // Move o alvo ao iniciar
    const interval = setInterval(moveTarget, speed); // Move o alvo em intervalos
    return () => clearInterval(interval);
  }, [speed]); // Dependência no speed

  return (
    <div
      className="absolute cursor-pointer transition-all ease-in-out"
      style={{
        width: size,
        height: size,
        left: position.x,
        top: position.y,
        transition: `left ${speed * 0.005}s, top ${speed * 0.005}s`, // Aumente a duração do movimento para ser visível
      }}
      onClick={(e) => {
        e.stopPropagation(); // Impede o clique de afetar o contêiner
        onClick();
        moveTarget(); // Muda a posição do alvo quando clicado
      }}
    >
      <div className="w-full h-full rounded-full bg-red-500 animate-pulse" />
    </div>
  );
}
