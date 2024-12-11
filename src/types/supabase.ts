export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          username: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          username?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          username?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      game_sessions: {
        Row: {
          id: string
          profile_id: string
          score: number
          misses: number
          accuracy: number
          target_size: number
          target_speed: number
          game_time: number
          created_at: string
        }
        Insert: {
          id?: string
          profile_id: string
          score: number
          misses: number
          accuracy: number
          target_size: number
          target_speed: number
          game_time: number
          created_at?: string
        }
        Update: {
          id?: string
          profile_id?: string
          score?: number
          misses?: number
          accuracy?: number
          target_size?: number
          target_speed?: number
          game_time?: number
          created_at?: string
        }
      }
      user_settings: {
        Row: {
          profile_id: string
          target_size: number
          target_speed: number
          game_time: number
          updated_at: string
        }
        Insert: {
          profile_id: string
          target_size?: number
          target_speed?: number
          game_time?: number
          updated_at?: string
        }
        Update: {
          profile_id?: string
          target_size?: number
          target_speed?: number
          game_time?: number
          updated_at?: string
        }
      }
    }
  }
}