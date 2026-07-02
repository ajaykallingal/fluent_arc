-- Supabase Database Schema for FluentArc

-- 1. Create the user_progress table
CREATE TABLE IF NOT EXISTS public.user_progress (
    uid UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    "lessonsCompleted" INTEGER DEFAULT 0,
    "grammarScoreAverage" NUMERIC(5, 2) DEFAULT 0.0,
    "vocabularyLearnedCount" INTEGER DEFAULT 0,
    "speakingSessionsCount" INTEGER DEFAULT 0,
    "streakDays" INTEGER DEFAULT 0,
    "lastActiveDate" TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (uid)
);

-- Enable Row Level Security (RLS) on user_progress
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- Create policies for user_progress
CREATE POLICY "Users can view their own progress" 
ON public.user_progress FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress" 
ON public.user_progress FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" 
ON public.user_progress FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own progress" 
ON public.user_progress FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);


-- 2. Create the conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sender TEXT CHECK (sender IN ('user', 'ai')),
    text TEXT,
    "timestamp" TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS) on conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Create policies for conversations
CREATE POLICY "Users can view their own chat messages" 
ON public.conversations FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own chat messages" 
ON public.conversations FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chat messages" 
ON public.conversations FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);
