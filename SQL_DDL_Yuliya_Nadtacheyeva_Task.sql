-- Set schema
SET search_path TO club_data;

-- Create Countries table if it does not exist
CREATE TABLE IF NOT EXISTS club_data.countries (
    country_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Create Areas table if it does not exist
CREATE TABLE IF NOT EXISTS club_data.areas (
    area_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Create Qualifications table if it does not exist
CREATE TABLE IF NOT EXISTS club_data.qualifications (
    qualification_id SERIAL PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

-- Create DifficultyLevels table if it does not exist
CREATE TABLE IF NOT EXISTS club_data.difficulty_levels (
    difficulty_level_id SERIAL PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

-- Create Mountains table, referencing Countries
CREATE TABLE IF NOT EXISTS club_data.mountains (
    mountain_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    height INT CHECK (height >= 0),
    country_id INT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES club_data.countries(country_id)
);

-- Create ClimbingRoutes table, referencing Mountains
CREATE TABLE IF NOT EXISTS club_data.climbing_routes (
    climbing_route_id SERIAL PRIMARY KEY,
    mountain_id INT NOT NULL,
    route_description TEXT NOT NULL,
    FOREIGN KEY (mountain_id) REFERENCES club_data.mountains(mountain_id)
);

-- Create Climbs table, referencing ClimbingRoutes and DifficultyLevels
CREATE TABLE IF NOT EXISTS club_data.climbs (
    climb_id SERIAL PRIMARY KEY,
    start_date DATE NOT NULL CHECK (start_date >= '2000-01-01'),
    end_date DATE NOT NULL CHECK (end_date >= start_date),
    climbing_route_id INT NOT NULL,
    difficulty_level_id INT NOT NULL,
    FOREIGN KEY (climbing_route_id) REFERENCES club_data.climbing_routes(climbing_route_id),
    FOREIGN KEY (difficulty_level_id) REFERENCES club_data.difficulty_levels(difficulty_level_id) 
);

-- Create enum type for gender
-- As alternative to using enum type, we can use a look up table or check constraint (CONSTRAINT check_valid_gender CHECK (gender IN ('Male', 'Female')))
CREATE TYPE gender_enum AS ENUM ('male', 'female');

-- Create Guides table, referencing Qualifications
CREATE TABLE IF NOT EXISTS club_data.guides (
    guide_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender gender_enum NOT NULL,
    contact_number VARCHAR(15) NOT NULL,
    qualification_id INT NOT NULL,
    FOREIGN KEY (qualification_id) REFERENCES club_data.qualifications(qualification_id)
);

-- Create Climbers table
CREATE TABLE IF NOT EXISTS club_data.climbers (
    climber_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender gender_enum NOT NULL,
    postal_address VARCHAR(100) NOT NULL,
    contact_number VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL
);

-- Create QualificationDifficultyLevels table, referencing Qualifications and DifficultyLevels
CREATE TABLE IF NOT EXISTS club_data.qualification_difficulty_levels (
    qualification_difficulty_level_id SERIAL PRIMARY KEY,
    qualification_id INT NOT NULL,
    difficulty_level_id INT NOT NULL,
    FOREIGN KEY (qualification_id) REFERENCES club_data.qualifications(qualification_id),
    FOREIGN KEY (difficulty_level_id) REFERENCES club_data.difficulty_levels(difficulty_level_id)
);

-- Create ClimbParticipants table, referencing Climbs and Climbers
CREATE TABLE IF NOT EXISTS club_data.climb_participants (
    climb_participants_id SERIAL PRIMARY KEY,
    climb_id INT NOT NULL,
    climber_id INT NOT NULL,
    FOREIGN KEY (climb_id) REFERENCES club_data.climbs(climb_id),
    FOREIGN KEY (climber_id) REFERENCES club_data.climbers(climber_id)
);

-- Create EmergencyContacts table, referencing Climbers
CREATE TABLE IF NOT EXISTS club_data.emergency_contacts (
    emergency_contact_id SERIAL PRIMARY KEY,
    climber_id INT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    contact_number VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    FOREIGN KEY (climber_id) REFERENCES club_data.climbers(climber_id)
);

-- Create GuideAssignments table, referencing Guides and Climbs
CREATE TABLE IF NOT EXISTS club_data.guide_assignments (
    guide_assignments_id SERIAL PRIMARY KEY,
    guide_id INT NOT NULL,
    climb_id INT NOT NULL,
    FOREIGN KEY (guide_id) REFERENCES club_data.guides(guide_id),
    FOREIGN KEY (climb_id) REFERENCES club_data.climbs(climb_id)
);

-- Create AreaCountries table, referencing Areas and Countries
CREATE TABLE IF NOT EXISTS club_data.area_countries (
    area_country_id SERIAL PRIMARY KEY,
    area_id INT NOT NULL,
    country_id INT NOT NULL,
    FOREIGN KEY (area_id) REFERENCES club_data.areas(area_id),
    FOREIGN KEY (country_id) REFERENCES club_data.countries(country_id)
);

-- Create Incidents table, referencing Climbs
CREATE TABLE IF NOT EXISTS club_data.incidents (
    incident_id SERIAL PRIMARY KEY,
    climb_id INT NOT NULL,
    description TEXT NOT NULL,
    date DATE NOT NULL CHECK (date >= '2000-01-01'),
    FOREIGN KEY (climb_id) REFERENCES club_data.climbs(climb_id)
);

ALTER TABLE club_data.climbers
ADD CONSTRAINT unique_climber_email UNIQUE (email);

-- Adding a climb_duration_days column
ALTER TABLE club_data.climbs
ADD COLUMN climb_duration_days INT GENERATED ALWAYS AS (end_date - start_date) STORED;

-- Inserting data into Countries table
INSERT INTO club_data.countries (country_id, name) VALUES
(1, 'Nepal'),
(2, 'Switzerland');

-- Inserting data into Areas table
INSERT INTO club_data.areas (area_id, name) VALUES
(1, 'Himalayas'),
(2, 'Alps');

-- Inserting data into Qualifications table
INSERT INTO club_data.qualifications (qualification_id, description) VALUES
(1, 'Basic Mountaineering'),
(2, 'Advanced Mountaineering');

-- Inserting data into DifficultyLevels table
INSERT INTO club_data.difficulty_levels (difficulty_level_id, description) VALUES
(1, 'Easy glacier route'),
(2, 'Not technical, but exposed to knife-edged ridges, weather, and high-altitude');

-- Inserting data into Mountains table
INSERT INTO club_data.mountains (mountain_id, name, height, country_id) VALUES
(1, 'Mount Everest', 8848, 1),
(2, 'Matterhorn', 4478, 2);

-- Inserting data into ClimbingRoutes table
INSERT INTO club_data.climbing_routes (climbing_route_id, mountain_id, route_description) VALUES
(1, 1, 'Southeast Ridge features a complex ascent, starting from the Khumbu Icefall, navigating through the Western Cwm, and the steep climb up the Lhotse Face to the South Col, culminating in a challenging traverse to the summit.'),
(2, 2, 'The Hörnli Ridge is the classic route on the Matterhorn, first ascended by Edward Whymper in 1865. It presents technical difficulties with sharp, rocky, and often near-vertical ascents. Climbers must be skilled in rock climbing techniques and prepared for sudden weather changes that can complicate the final sections of the ascent.');

-- Inserting data into Climbs table
INSERT INTO club_data.climbs (climb_id, start_date, end_date, climbing_route_id, difficulty_level_id) VALUES
(1, '2024-04-01', '2024-04-10', 1, 1),
(2, '2024-03-01', '2024-03-05', 2, 2);

-- Inserting data into Guides table
INSERT INTO club_data.guides (guide_id, first_name, last_name, gender, contact_number, qualification_id) VALUES
(1, 'Tenzing', 'Sherpa', 'male', '1234567890', 1),
(2, 'Edmund', 'Hillary', 'male', '0987654321', 2);

-- Inserting data into Climbers table
INSERT INTO club_data.climbers (climber_id, first_name, last_name, gender, postal_address, contact_number, email) VALUES
(1, 'John', 'Doe', 'male', '123 Everest Base Camp', '8001234567', 'john.doe@example.com'),
(2, 'Jane', 'Doe', 'female', '456 Lhotse Face', '8007654321', 'jane.doe@example.com');

-- Inserting data into QualificationDifficultyLevels table
INSERT INTO club_data.qualification_difficulty_levels (qualification_difficulty_level_id, qualification_id, difficulty_level_id) VALUES
(1, 1, 1),
(2, 2, 2);

-- Inserting data into ClimbParticipants table
INSERT INTO club_data.climb_participants (climb_participants_id, climb_id, climber_id) VALUES
(1, 1, 1),
(2, 2, 2);

-- Inserting data into EmergencyContacts table
INSERT INTO club_data.emergency_contacts (emergency_contact_id, climber_id, contact_name, relationship, contact_number, email) VALUES
(1, 1, 'Sarah Doe', 'Spouse', '9001234567', 'sarah.doe@example.com'),
(2, 2, 'Sam Doe', 'Sibling', '9007654321', 'sam.doe@example.com');

-- Inserting data into GuideAssignments table
INSERT INTO club_data.guide_assignments (guide_assignments_id, guide_id, climb_id) VALUES
(1, 1, 1),
(2, 2, 2);

-- Inserting data into AreaCountries table
INSERT INTO club_data.area_countries (area_country_id, area_id, country_id) VALUES
(1, 1, 1),
(2, 2, 2);

-- Inserting data into Incidents table
INSERT INTO club_data.incidents (incident_id, climb_id, description, date) VALUES
(1, 1, 'During a challenging expedition, a sudden and severe snowstorm led to visibility near zero, forcing the team to halt their ascent just below the South Summit. The climbers faced extreme cold and high winds, highlighting the unpredictable nature of high-altitude mountaineering. The incident prompted a review of weather forecasting interactions with expedition scheduling.', '2024-04-02'),
(2, 2, 'A rockslide on the lower sections of the Hörnli Ridge route resulted in significant path blockage. The event occurred early morning causing no injuries but necessitated a rapid response from the guide team to reroute the climb and assess further risks.', '2024-03-03');


ALTER TABLE club_data.countries
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.areas
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.qualifications
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.difficulty_levels
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.mountains
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.climbing_routes
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.climbs
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.guides
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.climbers
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.qualification_difficulty_levels
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.climb_participants
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.emergency_contacts
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.guide_assignments
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.area_countries
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE club_data.incidents
ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

SELECT * FROM club_data.countries;
SELECT * FROM club_data.areas;
SELECT * FROM club_data.qualifications;
SELECT * FROM club_data.difficulty_levels;
SELECT * FROM club_data.mountains;
SELECT * FROM club_data.climbing_routes;
SELECT * FROM club_data.climbs;
SELECT * FROM club_data.guides;
SELECT * FROM club_data.climbers;
SELECT * FROM club_data.qualification_difficulty_levels;
SELECT * FROM club_data.climb_participants;
SELECT * FROM club_data.emergency_contacts;
SELECT * FROM club_data.guide_assignments;
SELECT * FROM club_data.area_countries;
SELECT * FROM club_data.incidents;