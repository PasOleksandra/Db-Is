

-- створення таблиць

-- таблиця викладачів
CREATE TABLE public.teachers
(
    teacher_id serial,
    name character varying NOT NULL,
    PRIMARY KEY (teacher_id)
);

ALTER TABLE IF EXISTS public.teachers
    OWNER to postgres;

-- таблиця курсів
CREATE TABLE public.courses
(
    course_id serial,
    name character varying NOT NULL,
    teacher_id integer NOT NULL,
    description text,
    PRIMARY KEY (course_id),
    CONSTRAINT teacher_id FOREIGN KEY (teacher_id)
        REFERENCES public.teachers (teacher_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
        NOT VALID
);

ALTER TABLE IF EXISTS public.courses
    OWNER to postgres;

-- таблиця студентів
CREATE TABLE public.students
(
    student_id serial,
    name character varying NOT NULL,
    PRIMARY KEY (student_id)
);

ALTER TABLE IF EXISTS public.students
    OWNER to postgres;



-- вставка даних

-- вставка викладачів
INSERT INTO public.teachers (name)
VALUES
    ('Dr. Smith'),
    ('Prof. Johnson');

-- вставка курсів
INSERT INTO public.courses (name, teacher_id, description)
VALUES
    ('Math 101', 1, 'Introduction to Mathematics'),
    ('Physics 101', 2, 'Fundamentals of Physics');

-- вставка студентів
INSERT INTO public.students (name)
VALUES
    ('Charlie'),
    ('Bob');


-- вибірка даних

SELECT * FROM public.teachers;

SELECT * FROM public.courses;

SELECT * FROM public.students;



-- оновлення даних
UPDATE public.students SET name = 'Sasha' WHERE student_id = 1;

-- видалення даних
DELETE FROM public.teachers WHERE teacher_id = 1;
