CREATE TABLE savings_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL CHECK (amount > 0),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sos_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    trigger_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    selected_mode VARCHAR(50) NOT NULL CHECK (selected_mode IN ('WAIT_5_MINS', '4_7_8_BREATHING')),
    distraction_clicked VARCHAR(50) CHECK (distraction_clicked IN ('WATER', 'FRIEND', 'WALK'))
);

CREATE TABLE user_mission_progress (
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    mission_id UUID NOT NULL,
    progress_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (user_id, mission_id, progress_date)
);

CREATE TABLE wishlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    item_name VARCHAR(150) NOT NULL,
    target_amount INTEGER NOT NULL CHECK (target_amount > 0),
    category_icon VARCHAR(50) NOT NULL,
    is_achieved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

