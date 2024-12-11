export interface Settings {
  targetSize: number;
  targetSpeed: number;
  gameTime: number;
}

export type GameState = 'idle' | 'playing' | 'ended';