-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 26-02-2026 a las 11:39:48
-- Versión del servidor: 11.4.9-MariaDB-cll-lve
-- Versión de PHP: 8.4.17

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `amatistacom_amatistacom_laravel`
--
CREATE DATABASE IF NOT EXISTS `amatistacom_amatistacom_laravel` DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci;
USE `amatistacom_amatistacom_laravel`;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria`
--

CREATE TABLE `auditoria` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `user_nombre` varchar(100) DEFAULT NULL,
  `accion` varchar(20) NOT NULL,
  `modelo` varchar(50) NOT NULL,
  `registro_id` bigint(20) UNSIGNED NOT NULL,
  `datos_anteriores` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`datos_anteriores`)),
  `datos_nuevos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`datos_nuevos`)),
  `ip` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `auditoria`
--

INSERT INTO `auditoria` (`id`, `user_id`, `user_nombre`, `accion`, `modelo`, `registro_id`, `datos_anteriores`, `datos_nuevos`, `ip`, `created_at`) VALUES
(1, NULL, NULL, 'created', 'User', 1, NULL, '{\"name\":\"Administrador\",\"email\":\"amatista@gmail.com\",\"rol\":\"admin\",\"updated_at\":\"2026-02-07 15:29:27\",\"created_at\":\"2026-02-07 15:29:27\",\"id\":1}', '127.0.0.1', '2026-02-07 20:29:27'),
(2, 1, 'Administrador', 'login', 'User', 1, NULL, '{\"rol\":\"admin\"}', '38.25.8.68', '2026-02-07 20:30:12'),
-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cache`
--

INSERT INTO `cache` (`key`, `value`, `expiration`) VALUES
('amatista_cache_000d38e9b61f8b8528179386eb989b4c4b4024f0', 'i:10;', 1771099607),
('amatista_cache_000d38e9b61f8b8528179386eb989b4c4b4024f0:timer', 'i:1771099607;', 1771099607),
('amatista_cache_0efca449a17f55d50c74391106c0889bd850580a', 'i:1;', 1771071050),
('amatista_cache_0efca449a17f55d50c74391106c0889bd850580a:timer', 'i:1771071050;', 1771071050),
('amatista_cache_10b19665e285815c2359c72b3a898d9d46b88292', 'i:7;', 1771089629),
('amatista_cache_10b19665e285815c2359c72b3a898d9d46b88292:timer', 'i:1771089629;', 1771089629),
('amatista_cache_1fb5e55c0187c76cf95807481116f6f99c6ab707', 'i:1;', 1771286412),
('amatista_cache_1fb5e55c0187c76cf95807481116f6f99c6ab707:timer', 'i:1771286412;', 1771286412),
('amatista_cache_242a99921d32974a91b67084aec4ea9869d8d084', 'i:5;', 1771088446),
('amatista_cache_242a99921d32974a91b67084aec4ea9869d8d084:timer', 'i:1771088446;', 1771088446),
('amatista_cache_2693e0aa59df9913908ade41d741ab590af7702d', 'i:2;', 1771089248),
('amatista_cache_2693e0aa59df9913908ade41d741ab590af7702d:timer', 'i:1771089248;', 1771089248),
('amatista_cache_2b60ba311b75cd03cd09ca0b848c02dfd5dcc7d2', 'i:3;', 1771090877),
('amatista_cache_2b60ba311b75cd03cd09ca0b848c02dfd5dcc7d2:timer', 'i:1771090877;', 1771090877),
('amatista_cache_2c4636f20b0ea8d12d4abe6e51246972025538a6', 'i:2;', 1771068062),
('amatista_cache_2c4636f20b0ea8d12d4abe6e51246972025538a6:timer', 'i:1771068062;', 1771068062),
('amatista_cache_2e8be1ccc83fb2ae5615b4052143945a03a86e0c', 'i:5;', 1771096156),
('amatista_cache_2e8be1ccc83fb2ae5615b4052143945a03a86e0c:timer', 'i:1771096156;', 1771096156),
('amatista_cache_325775fda58e35e8a81faa398b8de1bb4f1168a3', 'i:1;', 1771084313),
('amatista_cache_325775fda58e35e8a81faa398b8de1bb4f1168a3:timer', 'i:1771084313;', 1771084313),
('amatista_cache_34dec1df1f6fa19bf0eab7be8ee2c2e5c2a66e3d', 'i:2;', 1771098181),
('amatista_cache_34dec1df1f6fa19bf0eab7be8ee2c2e5c2a66e3d:timer', 'i:1771098181;', 1771098181),
('amatista_cache_356a192b7913b04c54574d18c28d46e6395428ab', 'i:2;', 1771256503),
('amatista_cache_356a192b7913b04c54574d18c28d46e6395428ab:timer', 'i:1771256503;', 1771256503),
('amatista_cache_52b549b589ebdd9334ff3c9e4dc67019f1d1c663', 'i:2;', 1771094343),
('amatista_cache_52b549b589ebdd9334ff3c9e4dc67019f1d1c663:timer', 'i:1771094343;', 1771094343),
('amatista_cache_547e617d9fc3541587d5b3eb4d232ecc3437411a', 'i:1;', 1771772256),
('amatista_cache_547e617d9fc3541587d5b3eb4d232ecc3437411a:timer', 'i:1771772256;', 1771772256),
('amatista_cache_5926632eed9bacf8322c30960d19c4b1395e85fe', 'i:4;', 1771084932),
('amatista_cache_5926632eed9bacf8322c30960d19c4b1395e85fe:timer', 'i:1771084932;', 1771084932),
('amatista_cache_5fe87a74f24616da047f4ecb1834931fd62b1ad7', 'i:1;', 1771095575),
('amatista_cache_5fe87a74f24616da047f4ecb1834931fd62b1ad7:timer', 'i:1771095575;', 1771095575),
('amatista_cache_68e9ab1b5448de1bf90d52bf74cd6ee00dddcaa6', 'i:4;', 1771069247),
('amatista_cache_68e9ab1b5448de1bf90d52bf74cd6ee00dddcaa6:timer', 'i:1771069247;', 1771069247),
('amatista_cache_722d7ff03b7c38b370ad4ef09bd2b2f160b6b0f1', 'i:1;', 1771071872),
('amatista_cache_722d7ff03b7c38b370ad4ef09bd2b2f160b6b0f1:timer', 'i:1771071871;', 1771071872),
('amatista_cache_7ace18114d20e41c1d77a4cf1fd37da4342772d1', 'i:1;', 1771093648),
('amatista_cache_7ace18114d20e41c1d77a4cf1fd37da4342772d1:timer', 'i:1771093648;', 1771093648),
('amatista_cache_7c3ac3c2d619df7b89ff854e97040e4999f083b6', 'i:1;', 1770439210),
('amatista_cache_7c3ac3c2d619df7b89ff854e97040e4999f083b6:timer', 'i:1770439210;', 1770439210),
('amatista_cache_83e25045f49dbb9e3a175bc99b74c5cdd0cf5578', 'i:1;', 1772056220),
('amatista_cache_83e25045f49dbb9e3a175bc99b74c5cdd0cf5578:timer', 'i:1772056220;', 1772056220),
('amatista_cache_8cbae51c71accedb9eaa0f655b285dfe0d05340a', 'i:1;', 1771094344),
('amatista_cache_8cbae51c71accedb9eaa0f655b285dfe0d05340a:timer', 'i:1771094344;', 1771094344),
('amatista_cache_8ebea85a5eacb078807c90a8637155b7f4ccb703', 'i:1;', 1771540320),
('amatista_cache_8ebea85a5eacb078807c90a8637155b7f4ccb703:timer', 'i:1771540320;', 1771540320),
('amatista_cache_8ee3c8048cdce33697922fcd5947d191bc3ae1cd', 'i:1;', 1771187686),
('amatista_cache_8ee3c8048cdce33697922fcd5947d191bc3ae1cd:timer', 'i:1771187686;', 1771187686),
('amatista_cache_97756364a8ec1c62e131cd0f0d85cb6b1220c0db', 'i:1;', 1771072017),
('amatista_cache_97756364a8ec1c62e131cd0f0d85cb6b1220c0db:timer', 'i:1771072016;', 1771072016),
('amatista_cache_9a689be64fc9a44ed3c1c3c9419cd6cee35918d8', 'i:2;', 1771070697),
('amatista_cache_9a689be64fc9a44ed3c1c3c9419cd6cee35918d8:timer', 'i:1771070697;', 1771070697),
('amatista_cache_9ddf99693520489296e75ab3a82247b73575f284', 'i:1;', 1771093648),
('amatista_cache_9ddf99693520489296e75ab3a82247b73575f284:timer', 'i:1771093648;', 1771093648),
('amatista_cache_9ed44fbc0ae1bd1bdca0797c2dee79367cb81ed8', 'i:0;', 1771104700),
('amatista_cache_9ed44fbc0ae1bd1bdca0797c2dee79367cb81ed8:timer', 'i:1771104693;', 1771104693),
('amatista_cache_b7460f1b9013b7a99159a46215f73c31da309d89', 'i:1;', 1771067566),
('amatista_cache_b7460f1b9013b7a99159a46215f73c31da309d89:timer', 'i:1771067566;', 1771067566),
('amatista_cache_d4787e6227b130be68351081f5e99ae59ca8921c', 'i:1;', 1771089248),
('amatista_cache_d4787e6227b130be68351081f5e99ae59ca8921c:timer', 'i:1771089247;', 1771089248),
('amatista_cache_ddb51183ce3341f061c2cadb46d09dc17f96f6f7', 'i:1;', 1771087060),
('amatista_cache_ddb51183ce3341f061c2cadb46d09dc17f96f6f7:timer', 'i:1771087060;', 1771087060),
('amatista_cache_e86e7bb265fee22a6b2221db6c5b0691305b3233', 'i:2;', 1770993717),
('amatista_cache_e86e7bb265fee22a6b2221db6c5b0691305b3233:timer', 'i:1770993717;', 1770993717),
('amatista_cache_f305a8acfedb77b5ec1a01b1b259f82ebfb6a2be', 'i:1;', 1771093761),
('amatista_cache_f305a8acfedb77b5ec1a01b1b259f82ebfb6a2be:timer', 'i:1771093761;', 1771093761),
('amatista_cache_f75e377ecd52efb2a7bf0c3d7c2e8209b14ce23b', 'i:1;', 1771093648),
('amatista_cache_f75e377ecd52efb2a7bf0c3d7c2e8209b14ce23b:timer', 'i:1771093648;', 1771093648),
('amatista_cache_fdea9c843e5ce68b1a45936952def873cef60437', 'i:3;', 1771080281),
('amatista_cache_fdea9c843e5ce68b1a45936952def873cef60437:timer', 'i:1771080281;', 1771080281);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `conductores`
--

CREATE TABLE `conductores` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre` varchar(200) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `last_lat` decimal(10,8) DEFAULT NULL,
  `last_lng` decimal(11,8) DEFAULT NULL,
  `last_location_at` timestamp NULL DEFAULT NULL,
  `preferencia_distrito` varchar(50) DEFAULT NULL,
  `ubicacion` varchar(255) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `conductores`
--

INSERT INTO `conductores` (`id`, `nombre`, `telefono`, `activo`, `last_lat`, `last_lng`, `last_location_at`, `preferencia_distrito`, `ubicacion`, `token`, `created_at`, `updated_at`) VALUES
(1, 'Alejandro Canales', '990036869', 1, -11.90521530, -77.04295420, '2026-02-14 19:42:04', 'Cono Norte', NULL, 'd966ea3e-2665-4dd7-9c4e-69f6798171e9', '2026-02-09 20:32:48', '2026-02-14 19:42:04'),
(2, 'Cesar rivas', '987954662', 1, NULL, NULL, NULL, 'Cono Norte', NULL, '3b5c80ce-3181-4d63-b548-f0295229f73d', '2026-02-09 20:47:38', '2026-02-09 22:12:20'),
(3, 'Christian Alexander', '904466705', 1, NULL, NULL, NULL, 'Conor Sur y Cercado', NULL, 'b7070fa1-dbbc-432f-a7b8-fe109dffa7a6', '2026-02-12 16:04:59', '2026-02-12 16:04:59'),
(4, 'Johan', '928649325', 1, NULL, NULL, NULL, 'Cono Norte y Cercado de Lima', NULL, '18bcfb21-0f81-4424-9ead-6310993c9550', '2026-02-12 16:05:55', '2026-02-12 16:05:55'),
(5, 'joshymar saune', '933 339 798', 1, -12.11514037, -77.01797439, '2026-02-13 17:37:01', 'la molina', 'surquillo', '2cfba198-36ff-40d3-b100-96b67c0170e3', '2026-02-12 20:48:34', '2026-02-13 17:37:01'),
(6, 'Rafael Varela (MOTO)', '968652189', 1, NULL, NULL, NULL, NULL, 'surquillo', '62613ff5-e6d4-45d6-ae58-3fb3b4077559', '2026-02-13 20:45:01', '2026-02-14 00:13:25'),
(7, 'Yesenia Aguirre', '932951056', 1, -12.05881950, -77.02917820, '2026-02-14 18:58:35', 'Conor Sur,Cono Norte.', 'surquillo', '11c94784-4c82-4165-87d1-3f8c7a8d3075', '2026-02-14 00:18:54', '2026-02-14 18:58:35'),
(8, 'Juan Carlos Tafur', '942130654', 1, -12.09862041, -77.03545560, '2026-02-14 16:59:55', NULL, NULL, 'e232126b-d549-4a5a-9c2b-97f4da564d3c', '2026-02-14 11:10:44', '2026-02-14 16:59:55'),
(9, 'Luis Enrique', '944475324', 1, NULL, NULL, NULL, NULL, NULL, 'df42017f-2279-4385-ad48-0081b7ee0c18', '2026-02-14 13:53:56', '2026-02-14 13:53:56'),
(10, 'fiorella sanchez', '982767685', 1, -12.11848050, -76.99507840, '2026-02-14 16:59:59', NULL, NULL, 'dfc6190d-2748-491f-91fb-77a47fb2463b', '2026-02-14 13:55:24', '2026-02-14 16:59:59'),
(11, 'jose luis', '942349803', 1, NULL, NULL, NULL, NULL, NULL, '4b55865c-9f64-4a68-bf96-d9b48e4ed850', '2026-02-21 15:08:49', '2026-02-21 15:08:49');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `item_reportes`
--

CREATE TABLE `item_reportes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reporte_id` bigint(20) UNSIGNED NOT NULL,
  `producto_id` bigint(20) UNSIGNED NOT NULL,
  `cantidad` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `precio_unitario` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `item_reportes`
--

INSERT INTO `item_reportes` (`id`, `reporte_id`, `producto_id`, `cantidad`, `precio_unitario`, `created_at`, `updated_at`) VALUES
(5, 5, 2, 1, 260.00, '2026-02-09 16:09:45', '2026-02-09 16:09:45'),
(9, 7, 6, 1, 129.00, '2026-02-09 22:20:31', '2026-02-09 22:20:31'),
(10, 7, 16, 1, 165.00, '2026-02-09 22:20:31', '2026-02-09 22:20:31'),
(12, 9, 13, 1, 279.00, '2026-02-10 19:35:14', '2026-02-10 19:35:14'),
(13, 10, 6, 1, 129.00, '2026-02-10 20:15:06', '2026-02-10 20:15:06'),
(14, 11, 13, 1, 279.00, '2026-02-11 17:51:57', '2026-02-11 17:51:57'),
(16, 13, 2, 1, 260.00, '2026-02-11 18:32:56', '2026-02-11 18:32:56'),
(18, 15, 13, 1, 279.00, '2026-02-11 23:43:59', '2026-02-11 23:43:59'),
(19, 15, 20, 1, 36.00, '2026-02-11 23:43:59', '2026-02-11 23:43:59'),
(20, 15, 19, 1, 36.00, '2026-02-11 23:43:59', '2026-02-11 23:43:59'),
(21, 16, 16, 1, 165.00, '2026-02-11 23:54:03', '2026-02-11 23:54:03'),
(22, 17, 1, 1, 299.00, '2026-02-12 00:49:30', '2026-02-12 00:49:30'),
(23, 18, 6, 1, 129.00, '2026-02-12 15:59:46', '2026-02-12 15:59:46'),
(25, 19, 16, 1, 165.00, '2026-02-12 17:25:32', '2026-02-12 17:25:32'),
(26, 20, 17, 1, 305.00, '2026-02-12 20:19:59', '2026-02-12 20:19:59'),
(28, 4, 9, 1, 229.00, '2026-02-12 20:53:05', '2026-02-12 20:53:05'),
(29, 22, 16, 1, 165.00, '2026-02-12 21:17:36', '2026-02-12 21:17:36'),
(30, 22, 22, 1, 119.00, '2026-02-12 21:17:36', '2026-02-12 21:17:36'),
(34, 23, 12, 1, 169.00, '2026-02-12 22:10:06', '2026-02-12 22:10:06'),
(36, 25, 17, 1, 305.00, '2026-02-13 00:34:24', '2026-02-13 00:34:24'),
(38, 27, 4, 1, 299.00, '2026-02-13 01:31:01', '2026-02-13 01:31:01'),
(41, 29, 6, 1, 129.00, '2026-02-13 02:32:43', '2026-02-13 02:32:43'),
(46, 32, 6, 1, 129.00, '2026-02-13 14:04:13', '2026-02-13 14:04:13'),
(47, 30, 19, 1, 36.00, '2026-02-13 14:10:46', '2026-02-13 14:10:46'),
(48, 30, 22, 1, 119.00, '2026-02-13 14:10:46', '2026-02-13 14:10:46'),
(49, 26, 23, 1, 199.00, '2026-02-13 14:11:30', '2026-02-13 14:11:30'),
(50, 21, 4, 1, 299.00, '2026-02-13 14:11:44', '2026-02-13 14:11:44'),
(51, 14, 14, 1, 199.00, '2026-02-13 14:11:57', '2026-02-13 14:11:57'),
(52, 12, 6, 1, 129.00, '2026-02-13 14:12:13', '2026-02-13 14:12:13'),
(53, 8, 15, 1, 199.00, '2026-02-13 14:12:29', '2026-02-13 14:12:29'),
(54, 3, 2, 1, 260.00, '2026-02-13 14:13:02', '2026-02-13 14:13:02'),
(55, 33, 18, 1, 169.00, '2026-02-13 15:25:29', '2026-02-13 15:25:29'),
(56, 34, 7, 1, 169.00, '2026-02-13 15:29:13', '2026-02-13 15:29:13'),
(57, 35, 14, 1, 199.00, '2026-02-13 15:37:17', '2026-02-13 15:37:17'),
(58, 36, 10, 1, 199.00, '2026-02-13 16:04:21', '2026-02-13 16:04:21'),
(59, 37, 13, 1, 279.00, '2026-02-13 16:45:48', '2026-02-13 16:45:48'),
(60, 39, 16, 1, 165.00, '2026-02-13 17:47:11', '2026-02-13 17:47:11'),
(61, 28, 16, 1, 165.00, '2026-02-13 17:59:20', '2026-02-13 17:59:20'),
(64, 42, 6, 1, 129.00, '2026-02-13 19:09:43', '2026-02-13 19:09:43'),
(65, 42, 19, 1, 36.00, '2026-02-13 19:09:43', '2026-02-13 19:09:43'),
(66, 43, 16, 1, 165.00, '2026-02-13 19:18:36', '2026-02-13 19:18:36'),
(67, 41, 15, 1, 199.00, '2026-02-13 19:18:56', '2026-02-13 19:18:56'),
(71, 45, 4, 1, 299.00, '2026-02-13 19:56:10', '2026-02-13 19:56:10'),
(72, 46, 1, 1, 299.00, '2026-02-13 20:16:35', '2026-02-13 20:16:35'),
(73, 47, 7, 1, 169.00, '2026-02-13 20:35:07', '2026-02-13 20:35:07'),
(74, 48, 3, 1, 329.00, '2026-02-13 20:48:52', '2026-02-13 20:48:52'),
(75, 49, 16, 1, 165.00, '2026-02-13 20:55:19', '2026-02-13 20:55:19'),
(81, 51, 16, 1, 165.00, '2026-02-13 21:28:36', '2026-02-13 21:28:36'),
(83, 53, 16, 1, 165.00, '2026-02-13 22:04:30', '2026-02-13 22:04:30'),
(90, 54, 7, 1, 169.00, '2026-02-13 22:10:11', '2026-02-13 22:10:11'),
(91, 54, 24, 1, 30.00, '2026-02-13 22:10:11', '2026-02-13 22:10:11'),
(92, 55, 18, 1, 169.00, '2026-02-13 22:24:24', '2026-02-13 22:24:24'),
(93, 55, 16, 1, 165.00, '2026-02-13 22:24:24', '2026-02-13 22:24:24'),
(94, 55, 23, 1, 199.00, '2026-02-13 22:24:24', '2026-02-13 22:24:24'),
(95, 56, 10, 1, 199.00, '2026-02-13 22:33:51', '2026-02-13 22:33:51'),
(96, 6, 6, 1, 129.00, '2026-02-13 22:39:01', '2026-02-13 22:39:01'),
(97, 57, 13, 1, 279.00, '2026-02-13 22:49:55', '2026-02-13 22:49:55'),
(98, 52, 17, 1, 305.00, '2026-02-13 22:56:36', '2026-02-13 22:56:36'),
(99, 44, 18, 1, 169.00, '2026-02-13 23:09:39', '2026-02-13 23:09:39'),
(101, 58, 16, 1, 165.00, '2026-02-13 23:39:40', '2026-02-13 23:39:40'),
(106, 50, 6, 1, 129.00, '2026-02-13 23:48:18', '2026-02-13 23:48:18'),
(107, 50, 19, 1, 36.00, '2026-02-13 23:48:18', '2026-02-13 23:48:18'),
(109, 59, 14, 1, 199.00, '2026-02-14 00:15:55', '2026-02-14 00:15:55'),
(115, 60, 5, 1, 299.00, '2026-02-14 00:36:32', '2026-02-14 00:36:32'),
(116, 61, 16, 1, 165.00, '2026-02-14 00:37:04', '2026-02-14 00:37:04'),
(117, 62, 4, 1, 299.00, '2026-02-14 00:43:09', '2026-02-14 00:43:09'),
(118, 62, 9, 1, 229.00, '2026-02-14 00:43:09', '2026-02-14 00:43:09'),
(120, 63, 10, 1, 199.00, '2026-02-14 01:29:31', '2026-02-14 01:29:31'),
(121, 64, 24, 1, 30.00, '2026-02-14 01:54:51', '2026-02-14 01:54:51'),
(122, 64, 6, 1, 129.00, '2026-02-14 01:54:51', '2026-02-14 01:54:51'),
(123, 64, 19, 1, 36.00, '2026-02-14 01:54:51', '2026-02-14 01:54:51'),
(125, 65, 16, 1, 165.00, '2026-02-14 02:01:43', '2026-02-14 02:01:43'),
(129, 69, 7, 1, 169.00, '2026-02-14 02:30:05', '2026-02-14 02:30:05'),
(130, 70, 15, 1, 199.00, '2026-02-14 02:32:40', '2026-02-14 02:32:40'),
(131, 66, 1, 1, 299.00, '2026-02-14 02:34:26', '2026-02-14 02:34:26'),
(132, 67, 11, 1, 169.00, '2026-02-14 02:46:53', '2026-02-14 02:46:53'),
(134, 68, 3, 1, 329.00, '2026-02-14 02:52:22', '2026-02-14 02:52:22'),
(135, 71, 16, 1, 165.00, '2026-02-14 03:03:12', '2026-02-14 03:03:12'),
(137, 38, 2, 1, 260.00, '2026-02-14 12:11:31', '2026-02-14 12:11:31'),
(138, 72, 16, 1, 165.00, '2026-02-14 13:37:26', '2026-02-14 13:37:26'),
(141, 74, 22, 1, 119.00, '2026-02-14 14:52:49', '2026-02-14 14:52:49'),
(142, 75, 6, 1, 129.00, '2026-02-14 15:00:29', '2026-02-14 15:00:29'),
(144, 77, 6, 1, 129.00, '2026-02-14 15:56:54', '2026-02-14 15:56:54'),
(145, 78, 22, 1, 119.00, '2026-02-14 16:02:01', '2026-02-14 16:02:01'),
(146, 76, 6, 1, 129.00, '2026-02-14 16:10:46', '2026-02-14 16:10:46'),
(147, 40, 16, 1, 165.00, '2026-02-14 16:39:33', '2026-02-14 16:39:33'),
(148, 79, 6, 1, 129.00, '2026-02-14 17:31:29', '2026-02-14 17:31:29'),
(149, 80, 6, 1, 129.00, '2026-02-14 17:50:31', '2026-02-14 17:50:31'),
(150, 81, 16, 1, 165.00, '2026-02-14 18:04:01', '2026-02-14 18:04:01'),
(151, 83, 2, 1, 260.00, '2026-02-14 18:18:04', '2026-02-14 18:18:04'),
(152, 84, 9, 1, 229.00, '2026-02-14 19:18:50', '2026-02-14 19:18:50'),
(153, 85, 16, 1, 165.00, '2026-02-14 19:19:50', '2026-02-14 19:19:50'),
(154, 86, 7, 1, 169.00, '2026-02-14 19:21:28', '2026-02-14 19:21:28'),
(155, 87, 13, 1, 279.00, '2026-02-14 19:32:15', '2026-02-14 19:32:15'),
(156, 89, 18, 1, 169.00, '2026-02-14 19:43:10', '2026-02-14 19:43:10'),
(157, 88, 16, 1, 165.00, '2026-02-14 19:46:36', '2026-02-14 19:46:36'),
(161, 92, 16, 1, 165.00, '2026-02-18 15:47:43', '2026-02-18 15:47:43'),
(162, 91, 6, 1, 129.00, '2026-02-18 15:47:59', '2026-02-18 15:47:59'),
(163, 90, 6, 1, 129.00, '2026-02-18 15:48:14', '2026-02-18 15:48:14'),
(164, 93, 25, 1, 170.00, '2026-02-18 19:44:29', '2026-02-18 19:44:29'),
(165, 94, 26, 1, 269.00, '2026-02-19 14:50:36', '2026-02-19 14:50:36'),
(166, 95, 27, 1, 217.00, '2026-02-20 13:28:10', '2026-02-20 13:28:10'),
(167, 96, 28, 1, 185.00, '2026-02-20 20:38:31', '2026-02-20 20:38:31'),
(168, 97, 30, 1, 125.00, '2026-02-21 19:18:44', '2026-02-21 19:18:44'),
(169, 97, 29, 1, 199.00, '2026-02-21 19:18:44', '2026-02-21 19:18:44'),
(170, 98, 31, 1, 70.00, '2026-02-21 20:21:35', '2026-02-21 20:21:35'),
(176, 99, 32, 1, 213.92, '2026-02-21 23:46:21', '2026-02-21 23:46:21'),
(177, 100, 11, 1, 109.00, '2026-02-23 19:41:04', '2026-02-23 19:41:04'),
(178, 100, 19, 1, 36.00, '2026-02-23 19:41:04', '2026-02-23 19:41:04'),
(179, 101, 24, 1, 30.00, '2026-02-24 16:57:43', '2026-02-24 16:57:43'),
(181, 102, 31, 1, 70.00, '2026-02-24 16:59:59', '2026-02-24 16:59:59'),
(185, 103, 11, 1, 109.00, '2026-02-24 17:10:27', '2026-02-24 17:10:27'),
(186, 103, 33, 1, 60.00, '2026-02-24 17:10:27', '2026-02-24 17:10:27'),
(187, 104, 34, 1, 199.00, '2026-02-24 19:57:18', '2026-02-24 19:57:18'),
(189, 106, 28, 1, 185.00, '2026-02-25 13:44:54', '2026-02-25 13:44:54'),
(190, 105, 35, 1, 49.00, '2026-02-25 13:45:11', '2026-02-25 13:45:11');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2024_01_01_000000_create_users_table', 1),

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre` varchar(200) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `stock` int(11) DEFAULT NULL COMMENT 'Null = Ilimitado',
  `imagen` varchar(255) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `nombre`, `precio`, `stock`, `imagen`, `activo`, `created_at`, `updated_at`) VALUES
(1, 'pasion eterna', 299.00, 10, 'productos/FjGzfxDINlOjpiNXChkEYF4TOkMtvSl6EW7bJvHG.jpg', 1, '2026-02-07 21:10:00', '2026-02-14 18:59:21'),
(2, 'encanto rojo', 260.00, NULL, 'productos/htgyMeo4x0PJhuzQhn4qNYlBJeSMmZMVmDtycaur.jpg', 1, '2026-02-07 21:10:33', '2026-02-09 22:26:24'),
(3, 'box 50 rosas premiun', 299.00, 9, 'productos/t7VfVVOEwkE4ymlGPn5OXsH7VfDJxDqtEy8148Mw.jpg', 1, '2026-02-07 21:11:30', '2026-02-23 19:38:13'),
(4, 'bouquet 50 rosas rojas', 179.00, 20, 'productos/E7iWeA86pVw2tOJs6GwGlpcddQ2LIViANCCKXngM.jpg', 1, '2026-02-07 21:12:00', '2026-02-23 19:37:50'),
(5, 'bouquet amor supremo', 299.00, 9, 'productos/fkvsSndpD4inrV1X5F9GKULag2EMzPYKv8OjlD3h.webp', 1, '2026-02-07 21:12:15', '2026-02-14 00:36:32'),
(6, 'bouquet 12 rosas pasion', 99.00, 38, 'productos/TVvVOXhaK7pHcpWqDjqq6o0H8fOZAZAeyks39quS.jpg', 1, '2026-02-07 21:12:40', '2026-02-23 19:37:59'),
(7, 'ramo sol radiante', 169.00, NULL, 'productos/WiWsS0QiUh8umBWM7CKNOkGmP2LE687yv9afbeK1.jpg', 1, '2026-02-07 21:13:37', '2026-02-13 15:14:40'),
(8, 'cesta amor infinito', 499.00, NULL, 'productos/KLWJhSFjBYDf6aVX1o7zHUaUgySCdKgLWfsgvjqd.jpg', 1, '2026-02-07 21:14:04', '2026-02-09 22:24:51'),
(9, 'box oso enamorado', 229.00, NULL, 'productos/vhNum9iowVArDcmmjzqYoQH3yCNu3RBKlO7EQifH.jpg', 1, '2026-02-07 21:14:22', '2026-02-09 22:23:56'),
(10, 'globo corona de amor', 199.00, NULL, 'productos/kHioMQHCjZP9IeS8Nz2VY2eM60oseAVfTmNuKl7V.jpg', 1, '2026-02-07 21:14:52', '2026-02-13 16:01:47'),
(11, 'box princess', 109.00, NULL, 'productos/Ty6Y6tfT7PVRwS6dcim0Q0xBhZAyUhROd6k75GAc.jpg', 1, '2026-02-09 15:09:40', '2026-02-23 19:38:22'),
(12, 'box princess red', 109.00, NULL, 'productos/5ZJs7GxDfXrD2CTm8YKjSrPBsSnrkdLtPzDs6mjk.jpg', 1, '2026-02-09 15:21:33', '2026-02-23 19:38:33'),
(13, 'lluvia de tulipanes', 279.00, NULL, 'productos/p8T9b0XJhBZSUFdDvasqAQlSGZpVy303EtWxMBdt.jpg', 1, '2026-02-09 15:25:58', '2026-02-13 20:15:43'),
(14, 'orquidea blanca', 199.00, NULL, 'productos/g1kTnED1Wlaf3ta3lH7mAHs0CSUh6zZP7ENwZM2Y.jpg', 1, '2026-02-09 15:37:53', '2026-02-09 22:27:03'),
(15, 'orquidea lila', 199.00, NULL, 'productos/eOU1vroCZOLYv6rWJhMHVebDF5vkDIMSQzQvSdBO.jpg', 1, '2026-02-09 15:38:13', '2026-02-09 22:27:13'),
(16, 'ramo 10 tulipanes', 165.00, 17, 'productos/SwnaOQyVIqj9iUOGaSijGuZktXuVkCu3nV3x2gak.jpg', 1, '2026-02-09 15:39:51', '2026-02-18 15:47:43'),
(17, 'dulce romance', 305.00, NULL, 'productos/yesFPZEKCsFgIGjyc3U5t4oBGvfjj1HP8aan3Xbh.jpg', 1, '2026-02-09 15:41:33', '2026-02-09 22:25:18'),
(18, 'dulzura en burbuja', 169.00, NULL, 'productos/fePr8K2PSUBlCOLCtUp4HlC9jeoPM1XmlxyqnBYA.jpg', 1, '2026-02-09 15:42:24', '2026-02-09 22:25:47'),
(19, 'chocolate ferrero roche', 36.00, NULL, 'productos/UanZDSt7NGYY9BZTsxL3Y7FhfDgAWVTo2W5dSQg2.jpg', 1, '2026-02-11 23:38:24', '2026-02-11 23:38:24'),
(20, 'chocolate hershey rosado', 36.00, NULL, 'productos/OWPhfSJCBGMjfKKr9yIihJjecoRvVRYy42Mf7F37.jpg', 1, '2026-02-11 23:39:09', '2026-02-11 23:39:09'),
(21, 'chocolate hersheys rojo', 36.00, NULL, 'productos/XPNHvWsaSYWYXJqlQy7kDEuQhBkj2PLPGxr9wPmW.jpg', 1, '2026-02-11 23:39:28', '2026-02-11 23:39:28'),
(22, 'love in and box red princess', 119.00, 6, 'productos/utZQvyctJV3mOifvJOVGrTxbKJ6V30plSdERLuJo.jpg', 1, '2026-02-12 20:08:07', '2026-02-14 16:28:37'),
(23, 'caja de tulipanes', 199.00, NULL, 'productos/fJdMyrdeNua44Dr9DgvlYd3CDeloss0POhqIfuNI.webp', 1, '2026-02-13 00:42:27', '2026-02-13 00:42:27'),
(24, 'globo burbuja', 30.00, NULL, 'productos/kjqav9ASiCCMeq0fIYGVgIq2gWrv7xIjrT9ALxlq.jpg', 1, '2026-02-13 22:05:55', '2026-02-13 22:05:55'),
(25, 'lleno de amor', 170.00, NULL, 'productos/dovoAL56qz6lD8EzA5PeFfwKdG7easdqEnqjP0gE.jpg', 1, '2026-02-18 19:41:31', '2026-02-18 19:41:31'),
(26, 'locura de amor', 269.00, NULL, 'productos/SoW7tG0ngGzZaMxo9O8Dv03GJrbfgvqYKOiiiRmk.jpg', 1, '2026-02-19 14:47:15', '2026-02-19 14:47:15'),
(27, 'Juntos y felices', 217.00, NULL, 'productos/gyvrJWHQzZp0nU2zrknMw3vK8NRxRKy9Z7z66TbU.jpg', 1, '2026-02-20 13:25:36', '2026-02-20 13:25:36'),
(28, 'happy birthaday', 185.00, NULL, 'productos/xdaPZ2j7hn2IzNRdyh8jYoTwl5nUlhDRBtawK9UN.jpg', 1, '2026-02-20 20:36:45', '2026-02-20 20:36:45'),
(29, 'jardin de emosiones', 199.00, NULL, 'productos/cJC5RnqcNCffYJOuIDPrs8petuni2FU0GWhiJceA.jpg', 1, '2026-02-21 19:09:53', '2026-02-21 19:09:53'),
(30, 'versos de amor', 125.00, NULL, 'productos/SQepzb7rmRWzFk5br1yN0I3VvkQ9rWTuhwlBHNow.jpg', 1, '2026-02-21 19:11:05', '2026-02-21 19:11:05'),
(31, 'caja de 12 rosas', 70.00, NULL, 'productos/7eWw2xLqb2HrIUgjgJWgEPIvwvanyE9DVnnnOQcI.jpg', 1, '2026-02-21 20:14:26', '2026-02-21 20:14:26'),
(32, 'arreglo personalizado', 213.92, NULL, 'productos/o4MbbEO7OyTXKkgFtV4ge3VjMEWPYf6uF2kiU9Z9.jpg', 1, '2026-02-21 21:28:10', '2026-02-21 23:30:55'),
(33, 'ramo de 6 rosas', 60.00, NULL, 'productos/CNkkpQrrKeRPpbFRNQqyVWNfLUrTpFVpeVyZ3SOi.jpg', 1, '2026-02-24 17:09:06', '2026-02-24 17:09:06'),
(34, 'atardecer de rosas', 199.00, NULL, 'productos/UlT9sEBNaYyP8iFBYtDLOYu2QcWoL1j687nMYZST.jpg', 1, '2026-02-24 19:55:12', '2026-02-24 19:55:12'),
(35, 'rayo de sol', 49.00, NULL, 'productos/3WS1liV1tzJqsMaamiNZuh8AyXGnwcDIywwvknb5.jpg', 1, '2026-02-25 13:40:30', '2026-02-25 13:40:30');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reporte_entregas`
--

CREATE TABLE `reporte_entregas` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre_cliente` varchar(200) NOT NULL,
  `telefono_cliente` varchar(20) NOT NULL,
  `fecha_compra` date NOT NULL,
  `fecha_entrega` date NOT NULL,
  `turno_entrega` varchar(20) NOT NULL DEFAULT 'manana',
  `observacion` text DEFAULT NULL,
  `nombre_destinatario` varchar(200) NOT NULL DEFAULT '',
  `telefono_destinatario` varchar(20) NOT NULL,
  `distrito` varchar(50) NOT NULL DEFAULT 'lima',
  `direccion_destinatario` text NOT NULL,
  `enlace_ubicacion` varchar(500) DEFAULT NULL,
  `tipo_ubicacion` varchar(20) NOT NULL DEFAULT 'casa',
  `dedicatoria` text DEFAULT NULL,
  `costo_delivery` decimal(10,2) NOT NULL DEFAULT 0.00,
  `metodo_pago` varchar(20) NOT NULL DEFAULT 'efectivo',
  `estado` varchar(20) NOT NULL DEFAULT 'pendiente',
  `estado_produccion` varchar(20) NOT NULL DEFAULT 'pendiente',
  `es_urgente` tinyint(1) NOT NULL DEFAULT 0,
  `produccion_iniciada_en` timestamp NULL DEFAULT NULL,
  `produccion_completada_en` timestamp NULL DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `conductor_id` bigint(20) UNSIGNED DEFAULT NULL,
  `nombre_conductor` varchar(200) NOT NULL DEFAULT '',
  `telefono_conductor` varchar(20) NOT NULL DEFAULT '',
  `foto_entrega` varchar(255) DEFAULT NULL,
  `observacion_conductor` text DEFAULT NULL,
  `fecha_confirmacion` timestamp NULL DEFAULT NULL,
  `estado_anterior` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `reporte_entregas`
--

INSERT INTO `reporte_entregas` (`id`, `nombre_cliente`, `telefono_cliente`, `fecha_compra`, `fecha_entrega`, `turno_entrega`, `observacion`, `nombre_destinatario`, `telefono_destinatario`, `distrito`, `direccion_destinatario`, `enlace_ubicacion`, `tipo_ubicacion`, `dedicatoria`, `costo_delivery`, `metodo_pago`, `estado`, `estado_produccion`, `es_urgente`, `produccion_iniciada_en`, `produccion_completada_en`, `created_by`, `conductor_id`, `nombre_conductor`, `telefono_conductor`, `foto_entrega`, `observacion_conductor`, `fecha_confirmacion`, `estado_anterior`, `created_at`, `updated_at`) VALUES
(3, 'WG', '958690844', '2026-01-28', '2026-02-13', 'manana', NULL, 'madeleine', '943168982', 'san_isidro', 'A.V Republica de panama, san isidro', NULL, 'oficina', NULL, 15.00, 'plin', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 2, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-09 15:58:03', '2026-02-13 16:54:41'),
(4, 'nelson tasayco', '944269091', '2026-02-06', '2026-02-12', 'tarde', NULL, 'angela liset celestino', '956352998', 'breña', 'pasaje nacario 162. Dptosol', NULL, 'casa', NULL, 20.00, 'yape', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 2, 2, 'Cesar rivas', '987954662', NULL, NULL, NULL, NULL, '2026-02-09 16:02:39', '2026-02-12 22:17:40'),
(5, 'gary', '994707723', '2026-02-03', '2026-02-14', 'manana', NULL, 'faviana cabral', '989012915', 'miraflores', 'calle aristedes aljovin 686', NULL, 'casa', NULL, 15.00, 'izipay', 'entregado', 'listo', 0, '2026-02-13 21:59:04', '2026-02-13 21:59:08', 2, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 15:21:46', 'en_ruta', '2026-02-09 16:09:45', '2026-02-14 15:21:46'),
(6, 'Juantxo Guibelalde', '949699075', '2026-02-09', '2026-02-14', 'manana', NULL, 'Encar Torre  966 405 311', '966 405 311', 'san_isidro', 'calle cura bejar 105 dpt. 401', NULL, 'casa', '*****adicional lleva 17 rosas rojas individuales)', 15.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 03:02:02', '2026-02-14 04:15:30', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'No me dieron', '2026-02-14 15:08:27', 'en_ruta', '2026-02-09 19:07:18', '2026-02-16 13:23:52'),
(7, 'Marcelo Zamora', '994747887', '2026-02-09', '2026-02-14', 'manana', NULL, 'Sara Amelia', '915055910', 'pueblo_libre', 'Angela Podesta 133', NULL, 'casa', 'ramo de rosas con colores pasteles\r\n\"Para mi amada, aunque la distancia física nos separe hoy, mi corazón está ahí con ustedes. Gracias por ser mi compañera, mi fuerza y por cuidar con tanto amor de nuestra familia. Eres el motor que me impulsa a seguir adelante cada día. Te amo y te extraño mucho.\"\r\n\r\n\"Para mi hermosa Thais Luana, aunque hoy no pueda darte un abrazo personalmente, quiero que estas flores te digan lo mucho que te quiero. Para mí eres mi hija, mi preciosa princesa  y siempre estaré para ti sin importar cuántos kilómetros nos separen. ¡Feliz 14 de febrero, hermosa!\"', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:48:25', '2026-02-14 07:50:20', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'A la mamá', '2026-02-14 18:47:52', 'reprogramado', '2026-02-09 22:19:06', '2026-02-14 18:47:52'),
(8, 'Rafa', '929282696', '2026-02-09', '2026-02-13', 'manana', NULL, 'Jimena Bardale', '929282696', 'san_borja', 'avenida de la opesis 155', NULL, 'oficina', 'La miré con tal persistencia que mi mirada atrajo la suya. Se fijó en mí unos instantes, tomó sus gemelos para cerciorarse de quién era yo, e indudablemente, creyó conocerme sin darse cuenta exacta de mi personalidad, puesto que al dejar sus gemelos, vagó por sus labios esa graciosa sonrisa con que saludan las mujeres bonitas cuando quieren contestar al saludo que esperan.\r\nEl corazón tiene razones que la razón no conoce, sobre todo cuando se trata de ti.', 15.00, 'yape', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-09 23:43:06', '2026-02-13 16:54:34'),
(9, 'Ricardo Aguilar', '946583545', '2026-02-10', '2026-02-14', 'manana', NULL, 'Rommy Pino Ramos', '997371386', 'la_victoria', 'avenida Las Americas 1509', NULL, 'casa', 'Para mí Chinita\r\nel Amor \r\nDe mi Vida \r\nCon todo mi corazón ❤️\r\nY por muchos \r\nSan Valentín mas\r\n\r\nTe amo por siempre \r\n\r\nRicardo', 20.00, 'izipay', 'entregado', 'listo', 0, '2026-02-13 22:00:51', '2026-02-13 22:01:28', 1, 1, 'Alejandro Canales', '990036869', NULL, 'Ningúna', '2026-02-14 13:54:32', 'en_ruta', '2026-02-10 19:35:13', '2026-02-14 13:54:32'),
(10, 'gerar', '913801174', '2026-02-10', '2026-02-14', 'manana', NULL, 'Mari Risco Segovia', '922367541', 'san_juan_lurigancho', 'mercado San Martin de porras puesto 45....Prolongación Los Granados Mz.W - Lt.12, San Juan de Lurigancho 15438, Perú', NULL, 'oficina', 'TE AMO MI AMOR', 30.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:48:22', '2026-02-14 07:50:23', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-10 20:15:05', '2026-02-16 13:23:42'),
(11, 'ramon deheza', '998178066', '2026-02-11', '2026-02-13', 'tarde', NULL, 'lorena leon', '998178066', 'san_isidro', 'los castaños 351 dpto. 302', NULL, 'casa', 'Ramón, Joaquin y valentina', 0.00, 'yape', 'entregado', 'listo', 0, '2026-02-13 20:06:26', '2026-02-13 20:17:42', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-11 17:51:56', '2026-02-14 03:01:42'),
(12, 'rodrigo lara', '953844607', '2026-02-11', '2026-02-13', 'manana', NULL, 'josselyn peña', '961549783', 'la_molina', 'avenida la molina 190 (oficina atento)', NULL, 'oficina', 'Mi bobita, se que no estamos en nuestros mejores momentos, se que estamos trabajando para poder tener un futuro mejor y poder cumplir todas las promesas que nos hemos hecho. Este pequeño detalle es para ti, para que veas que siempre te tengo presente en mi mente y corazón. \r\nEspero que te guste mucho este presente, te amo ❤️.', 20.00, 'yape', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 1, NULL, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-11 18:10:43', '2026-02-13 16:56:33'),
(13, 'luis morales', '(+1) 8313321425', '2026-02-11', '2026-02-14', 'manana', NULL, 'Mariel Jeri', '980761391', 'san_borja', 'pablo usandizaga 670', NULL, 'casa', 'Con todo mi AMOR  Chanchita\r\n1:26 PM', 32.00, 'izipay', 'entregado', 'listo', 0, '2026-02-13 21:59:31', '2026-02-13 21:59:37', 1, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 20:06:01', 'en_ruta', '2026-02-11 18:32:56', '2026-02-14 20:06:01'),
(14, 'marcela  ruiz gonzales', '987768037', '2026-02-11', '2026-02-13', 'manana', NULL, 'marcela ruiz gonzales', '98778037', 'lima', 'Jr. carabaya 341', NULL, 'oficina', NULL, 20.00, 'yape', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 2, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-11 20:56:21', '2026-02-13 16:54:23'),
(15, 'wilson', '929625071', '2026-02-11', '2026-02-13', 'manana', NULL, 'Ingrid Nevado', '934957595', 'independencia', 'Avenida Carlos Izaguirre 176 Ministerio Publico', NULL, 'oficina', 'carita', 30.00, 'bcp', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-11 23:43:58', '2026-02-13 16:56:40'),
(16, 'sin nombre', '906946932', '2026-02-11', '2026-02-14', 'manana', NULL, 'wendy Berrios', '996642560', 'magdalena', 'Juan de Aliga 456', NULL, 'casa', 'En la vida siempre es importante esa persona, que sea a la vez, espejo y sombra .\r\nEl espejo nunca miente y la sombra nunca se aleja\r\n\r\nFeliz 14\r\nTu incógnito', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 02:09:49', '2026-02-14 02:09:56', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok se espero 10 minutos', '2026-02-14 14:46:58', 'en_ruta', '2026-02-11 23:54:00', '2026-02-14 14:46:58'),
(17, 'Wilmer Matos', '953844397', '2026-02-11', '2026-02-14', 'manana', NULL, 'Nelly Robles', '953844397', 'santiago_surco', 'Calle Majes 127', NULL, 'casa', NULL, 18.00, 'plin', 'entregado', 'listo', 0, '2026-02-13 22:00:02', '2026-02-13 22:00:05', 1, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 16:59:56', 'en_ruta', '2026-02-12 00:49:30', '2026-02-14 16:59:56'),
(18, 'jhon mejias', '941958045', '2026-02-12', '2026-02-14', 'manana', NULL, 'Maria Gracia Garcia', '996138907', 'jesus_maria', 'Jiron Costa Rica 140', NULL, 'casa', 'Este 14 de febrero no solo celebro nuestro amor, sino la hermosa familia que hemos construido juntos. Gracias por ser mi compañera, mi apoyo y el corazón de nuestro hogar.\r\n\r\nVerte como esposa y como madre de nuestro hijo me llena de orgullo y admiración cada día. Eres una mujer increíble, fuerte, dulce y llena de amor.\r\nTE AMO \r\nJohn .', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:48:16', '2026-02-14 07:50:15', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Conserje', '2026-02-14 15:18:26', 'en_ruta', '2026-02-12 15:59:46', '2026-02-14 15:18:26'),
(19, 'roberto blados', '+51 940 233 983', '2026-02-12', '2026-02-14', 'manana', NULL, 'vanesa rios', '940 233 983', 'pueblo_libre', 'av del rio 291  dpt 802', NULL, 'casa', 'Feliz día de San Valentín mi amorcito, te amo', 20.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 02:10:14', '2026-02-14 02:10:17', 2, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Esposo', '2026-02-14 13:12:12', 'en_ruta', '2026-02-12 17:25:01', '2026-02-14 13:12:12'),
(20, 'Ernesto Jaimes', '993453058', '2026-02-12', '2026-02-14', 'manana', NULL, 'Mariella Feria', '993453058', 'santiago_surco', 'Jiron Aguada Blanca 119 Dpto. 201', NULL, 'casa', 'Hola Jamoncita, mi Jamoncita!!\r\n\r\nFeliz día de la mordida mi Jamoncita!!\r\n\r\nYa casi perdí la cuenta, pero creo que ya es la décima celebración Jamoncita!!… aunque claro que al comienzo no habían mordidas 🤔  pero si mucho amor y bastante calor, más aún en las noches de verano jejeje.\r\n\r\nSon ya casi 10 años amorcito que estamos juntos y todos valieron el dolor, digo la pena, porque no me imagino hoy la vida sin ti, llegar a la casa y verte o recogerte cuando vienes de trabajar tan cansada que me da gana de cargarte hasta el carro, pero ya sabes, no se puede porque eres más grande que yo.\r\n\r\nDécima celebración mi amor y nos queda mucho más, muchas aventuras y retos que seguir superando juntos!! Te amo mi amorcito y espero siempre hacer todo lo posible para hacerte MUY FELIZ!!\r\n\r\n(Por ahora no te escribo más porque mucho sapo, pero ya te lo diré en persona)\r\n\r\nFELIZ DÍA DE SAN VALENTÍN MI BELLA PRINCESA!!! ❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️', 18.00, 'plin', 'entregado', 'listo', 0, '2026-02-13 22:00:30', '2026-02-13 22:00:35', 1, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 20:05:57', 'en_ruta', '2026-02-12 20:19:59', '2026-02-14 20:05:57'),
(21, 'Jorge Hoyos', '978725040', '2026-02-12', '2026-02-12', 'tarde', NULL, 'Jorge Hoyos', '978725040', 'surquillo', 'Calle Victor Matilla 544', NULL, 'oficina', 'Gracias por todo lo que haces por mí, por nuestra familia y por todos los que te rodean. En este día del amor, recuerda que eres el gran amor de mi vida. TE AMO MI AMOR💕', 0.00, 'yape', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 1, NULL, 'joshymar saune', '933 339 798', NULL, NULL, NULL, NULL, '2026-02-12 20:24:29', '2026-02-16 13:23:35'),
(22, 'Darwib', '989271457', '2026-02-12', '2026-02-14', 'manana', NULL, 'Yesica Cruz   Cecilia Zelaya', '989271457', 'comas', 'Jiron San Gregorio 617', NULL, 'casa', 'Tulipanes \r\nPara mi amada esposa con mucho amor, sigas adelante a pesar de los años\r\nDe: Tu esposo Darwin Mora R. Ídem.\r\n\r\nRosas\r\nEn este día tan especial un hermoso ramo de flores para una gran madre y mujer, con toda estima, respeto y cariño. \r\nDe: sus hijos y yerno.', 30.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 02:06:17', '2026-02-14 02:06:26', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-12 21:17:36', '2026-02-16 13:23:12'),
(23, 'klein', '+51 943 550 891', '2026-02-12', '2026-02-14', 'manana', NULL, 'ana martel', '943550891', 'miraflores', 'av federico villareal 454 miraflores', NULL, 'casa', 'Feliz día del amor mi Reina, gracias por compartir tu corazón conmigo. Te amo.', 12.00, 'yape', 'entregado', 'listo', 0, '2026-02-13 21:58:42', '2026-02-13 21:58:45', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 15:08:39', 'en_ruta', '2026-02-12 22:10:06', '2026-02-14 15:08:39'),
(25, 'Bruno Francisco', '946540193', '2026-02-12', '2026-02-14', 'manana', NULL, 'Fiorella Araceli Yauramiza', '987181792', 'ate', 'Calle Bilbao Mz.S1, Lote 21 Dpto 501', 'https://www.google.com/maps/place/12%C2%B003\'38.8%22S+76%C2%B056\'27.7%22W/@-12.0607681,-76.9436073,17z/data=!3m1!4b1!4m4!3m3!8m2!3d-12.0607681!4d-76.9410324?hl=es&entry=ttu&g_ep=EgoyMDI2MDIxMC4wIKXMDSoASAFQAw%3D%3D', 'casa', 'Fiorella,\r\nNo siempre somos perfectos, ni nuestros días lo son, pero lo que siento por ti es real y constante. Gracias por estar, por apoyarme y por creer en mí.\r\nA veces me equivoco, y a veces no sé cómo darte todo lo que quisieras, pero nunca dejo de quererte ni de intentar hacerlo mejor por nosotros.\r\nHemos cumplimos un año y, aunque no estemos pasando nuestro mejor momento, quiero que sepas que sigo aquí, eligiéndote, valorándote y queriendo construir contigo nuestras vidas.\r\nEres mi chica, la mujer que amo, y tengo muchas ilusiones contigo.\r\nTe amo, Fiorella, más de lo que a veces sé expresar.\r\nFeliz San Valetín.\r\nCon todo mi corazón.\r\nBruno', 30.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-13 22:02:35', '2026-02-13 22:02:40', 1, 9, 'Luis Enrique', '944475324', NULL, 'Se tocó varias veces su puerta y nadie salió. Avisar si se regresará de nuevo', '2026-02-14 17:40:17', 'en_ruta', '2026-02-13 00:34:24', '2026-02-16 13:23:28'),
(26, 'alain', '997893193', '2026-02-05', '2026-02-13', 'tarde', NULL, 'frizzia villena bernal', '941366464', 'san_borja', 'calle 10 414 monterrico norte', NULL, 'casa', 'Es nuestro 15vo día de los enamorados..!! Hoy somos esposos y tenemos una hermosa familia.  Agradezco a Dios por haber cruzado nuestros caminos y por darme la dicha de poder compartir contigo un año más...!!!  Aunque no necesito una fecha especial para recordarte cuanto te amo, espero que te guste este detalle.', 18.00, 'izipay', 'entregado', 'listo', 0, '2026-02-13 20:11:38', '2026-02-13 20:17:53', 1, 6, 'Rafael Varela (MOTO)', '968652189', NULL, NULL, NULL, NULL, '2026-02-13 00:47:22', '2026-02-13 20:48:03'),
(27, 'Carlos Paredes', '993136116', '2026-02-12', '2026-02-14', 'manana', NULL, 'Rebeca Calderon', '989484733', 'rimac', 'Totorita Mz E, lt. 1', 'https://www.google.com/maps/place/Gral.+Vidal+%26+Av.+Francisco+Pizarro,+R%C3%ADmac+15094/@-12.0340663,-77.0373685,75m/data=!3m1!1e3!4m6!3m5!1s0x9105cf36ceb8c161:0x62d8dc913bef9dcf!8m2!3d-12.0337324!4d-77.038742!16s%2Fg%2F11gdz9wl_y?entry=ttu&g_ep=EgoyMDI2MDIxMC4wIKXMDSoASAFQAw%3D%3D', 'casa', NULL, 25.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 09:47:44', '2026-02-14 09:48:22', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-13 01:31:01', '2026-02-16 13:23:07'),
(28, 'Erick Chinchayau', '949559787', '2026-02-12', '2026-02-13', 'manana', NULL, 'Iris Diaz', '921634317', 'san_isidro', 'Avenida Arequipa 2637', NULL, 'oficina', 'Detrás de tu forma reservada hay algo que me encanta descubrir.\r\nEres hermosa, y me gustas más de lo que imaginas', 18.00, 'payum', 'entregado', 'listo', 0, '2026-02-13 20:00:32', '2026-02-13 20:00:38', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 01:47:58', '2026-02-13 20:47:45'),
(29, 'cristian', '996890207', '2026-02-12', '2026-02-14', 'manana', NULL, 'rocio tarazona', '999348200', 'breña', 'calle mariano', NULL, 'casa', 'Feliz día de San Valentín  \r\nMi Chío !!!\r\nQue hoy y siempre sea un día feliz para nosotros y nuestros hijos !!!\r\nCon amor Cristiam\r\nFebrero - 2026', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:48:29', '2026-02-14 07:50:28', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Falta dirección y no contesta el celular4', '2026-02-14 18:30:06', 'reprogramado', '2026-02-13 02:32:43', '2026-02-14 18:30:06'),
(30, 'Rogger', '991128850', '2026-02-12', '2026-02-13', 'manana', NULL, 'Camila Ramirez', '967791133', 'lima', 'Jiron Camana 1043 edificio recoleta', NULL, 'oficina', 'Cuando alguien te mueve el corazón, se nota y se celebra.\r\nQue hoy sonrías mucho más! con eso ya es suficiente para mi.\r\n\r\nCon mucho cariño y amor\r\n\r\nRQ', 20.00, 'efectivo', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-13 03:32:05', '2026-02-13 16:54:29'),
(32, 'piero paz', '992495184', '2026-02-13', '2026-02-14', 'manana', NULL, 'andrea perez', '937381891', 'santiago_surco', 'galicia 142 surco higuereta', NULL, 'casa', '“Espero que alegren tu dia. Gracias x lo compartido y por tu apertura conmigo. Departe de alguien que te dijo que no queria ser amigo…pero no puede sacarte de su cabeza, ni de sus sueños. Feliz San Valentin 🫶🏻”', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:48:33', '2026-02-14 07:50:30', 2, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 16:54:29', 'en_ruta', '2026-02-13 14:04:13', '2026-02-14 16:54:29'),
(33, 'miguel', '991117104', '2026-02-13', '2026-02-13', 'tarde', NULL, 'miguel ruiz mezones', '991117104', 'san_borja', 'jr juan de velde 142', NULL, 'casa', 'Que pases un feliz dia', 18.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-13 20:17:15', '2026-02-13 20:39:04', 4, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 15:25:28', '2026-02-14 02:58:24'),
(34, 'arom', '+51 998 809 922', '2026-02-13', '2026-02-14', 'manana', NULL, 'maria echegoyen sotomayor', '947 485 268', 'la_molina', 'carril derecho de la Avenida la Molina Este 178,', 'https://maps.app.goo.gl/MJWdc7BCrvYMmezd6', 'casa', '“Entre tanta gente y tantos días, justo tú y yo terminamos encontrándonos, y desde entonces todo se siente más bonito. \r\nDe: Aarón”', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 09:47:47', '2026-02-14 09:48:24', 4, 9, 'Luis Enrique', '944475324', NULL, 'Entrega a la misma señorita', '2026-02-14 17:38:19', 'en_ruta', '2026-02-13 15:29:13', '2026-02-14 17:38:19'),
(35, 'Pame', '992898130', '2026-02-13', '2026-02-13', 'manana', NULL, 'Sherlie Tello', '966420765', 'lima', 'jiron Puno 914, edificio Yang piso 4', NULL, 'oficina', 'Feliz Día de la Amistad, estimada Shirley\r\n\r\nGracias por por tu apoyo constante, en especial en los momentos complicados en los que se necesita una palabra de aliento. \r\nValoramos cada gesto tuyo con nuestro hogar y proyecto profesional\r\n\r\nCon cariño:  Pamela y Wlliam', 20.00, 'efectivo', 'entregado', 'listo', 0, NULL, '2026-02-13 17:06:47', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 15:37:17', '2026-02-13 16:56:21'),
(36, 'anonimo', '99999999', '2026-02-13', '2026-02-14', 'manana', NULL, 'Giuliana Kristel Echeverría Vargas', '956 079 749', 'comas', 'Calle Colmena Nro. 620 - Comas (Casa).', 'https://maps.app.goo.gl/zfMiC1eouXaK4Qz37', 'casa', 'Por la que despierto con una sonrisa cada día.\"\r\n\"A tu lado, el mundo pesa menos y el corazón late más fuerte.\"\r\n\r\n*Remitente: Anónimo.', 35.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 07:51:58', '2026-02-14 07:54:08', 4, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-13 16:04:21', '2026-02-16 13:23:00'),
(37, 'franz', '983702130', '2026-02-13', '2026-02-13', 'tarde', NULL, 'diana caceres mori', '947360101', 'san_miguel', 'maranga 4to etapa', NULL, 'casa', 'Siempre serás mi San Valentín de por vida, Te amo Esposita ❤️', 25.00, 'bcp', 'entregado', 'listo', 0, '2026-02-13 20:11:51', '2026-02-13 20:17:48', 2, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 16:45:47', '2026-02-14 02:59:00'),
(38, 'ricardo', '981449594', '2026-02-13', '2026-02-14', 'manana', NULL, 'Roxana Karyn roncal', '991137257', 'santa_anita', 'Av. Los Ruiseñores 215 santa anita', NULL, 'casa', 'Una linda casualidad fue testigo de un bonito amor que se unió al conocerte Roxana', 30.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 10:44:28', '2026-02-14 13:48:04', 4, 9, 'Luis Enrique', '944475324', NULL, 'No está la persona que recibe, se regresará a las 15:00 horas', '2026-02-14 17:39:37', 'en_ruta', '2026-02-13 17:07:04', '2026-02-16 13:30:56'),
(39, 'juanga', '+51 912 474 371', '2026-02-13', '2026-02-14', 'manana', NULL, 'Nitssa Ennith de la Riva Torres', '983 795 346', 'lima', 'Av. Petit Thouars 455, Lima 15046', 'https://maps.app.goo.gl/Lvmg2fpRT2oBEm89A', 'casa', 'Con mucho amor para la chica mas linda de todas.\r\n       Feliz día de San Valentín.\r\n        DE: 🕊️', 25.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 02:10:36', '2026-02-14 02:10:40', 4, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Personalmente', '2026-02-14 17:19:54', 'reprogramado', '2026-02-13 17:47:11', '2026-02-14 17:19:54'),
(40, 'carlos', '945869800', '2026-02-13', '2026-02-14', 'manana', NULL, 'ludi jheni rojas', '945869800', 'san_juan_miraflores', 'calle manuel  bonilla 480', NULL, 'casa', 'Jheni, esposa mía:\r\nNo hay regalo que alcance para agradecerte todo lo que haces por nosotros.\r\nEres mi compañera, mi apoyo y el corazón de nuestro hogar.\r\nGracias por ser una esposa increíble y una mamá maravillosa.\r\nEsto es un pequeño detalle para recordarte cuánto te amamos.\r\nCon todo nuestro amor!\r\n \r\nAlessandra y Carlos', 15.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 02:10:51', '2026-02-14 02:10:58', 2, 7, 'Yesenia Aguirre', '932951056', NULL, '8 llamadas , mensajes de WhatsApp nunca respondió', '2026-02-14 13:18:00', 'en_ruta', '2026-02-13 18:09:51', '2026-02-16 13:30:50'),
(41, 'breña zorritos', '932191291', '2026-02-13', '2026-02-13', 'manana', NULL, 'Pamela Gonzalez', '992898130', 'jesus_maria', 'Av. General Santa Cruz 673 departamento 1002 \r\nEdificio Green park', NULL, 'oficina', 'Gracias por TaDa la oportunidad que me das, eres y serás el amor de mi vida, mi compromiso y promesa de amarte estarán siempre, te amo.\r\nTu Esposo', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-13 20:59:49', '2026-02-13 21:02:27', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 19:07:49', '2026-02-14 02:58:54'),
(42, 'Ernesto Laq Puente', '980100419', '2026-02-13', '2026-02-13', 'manana', NULL, 'Carin Grandez', '965799632', 'lima', 'Jiron Loreto 290', NULL, 'oficina', 'Para ti mi bebé en el día del amor, feliz día y que cumplamos muchos más. I love you\r\nErnesto', 35.00, 'yape', 'entregado', 'listo', 0, '2026-02-13 20:17:29', '2026-02-13 21:54:23', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 19:09:43', '2026-02-14 02:58:48'),
(43, 'agente', '939621548', '2026-02-13', '2026-02-13', 'manana', NULL, 'mireya cerna quiñe', '987387253', 'miraflores', 'Av. Andrés Avelino Cáceres 320, Miraflores 15047', NULL, 'casa', '“Mireya, eres el latido más bonito de mi corazón.”', 15.00, 'izipay', 'entregado', 'listo', 0, '2026-02-13 20:06:10', '2026-02-13 21:02:18', 4, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 19:18:36', '2026-02-14 02:58:36'),
(44, 'TANIA', '+51 913 947 574', '2026-02-13', '2026-02-14', 'manana', NULL, 'ELUTA VELZAQUES', '913947574', 'santa_anita', 'av. Los chancas de andaguaylas 109 santa anita', NULL, 'casa', '\"Eres la hermana que me hace sentir invincible, te quiero mucho hermanita\"', 20.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 04:26:02', '2026-02-14 04:26:49', 4, 9, 'Luis Enrique', '944475324', NULL, 'La dirección no estaba correcta', '2026-02-14 15:44:48', 'en_ruta', '2026-02-13 19:30:57', '2026-02-14 15:44:48'),
(45, 'nicolas paz', '932908282', '2026-02-13', '2026-02-13', 'manana', NULL, 'nicolas paz', '932908282', 'san_isidro', 'Avenida Coronel Portillo 396, San Isidro', NULL, 'casa', 'dedicatoria vacia', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-13 20:06:17', '2026-02-13 21:02:21', 4, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 19:39:46', '2026-02-14 02:58:07'),
(46, 'MICAHEL', '+51 935 736 037', '2026-02-13', '2026-02-13', 'manana', NULL, 'ZIOLA MENDOZA CALVO', '954 776 984', 'santiago_surco', 'Av. Paseo La Castellana 672 dpto 401', NULL, 'casa', 'Por más lejos que esté, tú amor siempre alimenta mis deseos de continuar y mis ganas de volver y de hacer mejor las cosas con todo el amor \r\n\r\ntu esposo', 20.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-13 21:03:09', '2026-02-14 01:22:44', 4, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 20:16:34', '2026-02-14 02:58:43'),
(47, 'jhony gomesz', '900740395', '2026-02-13', '2026-02-13', 'tarde', NULL, 'daniela naramjo quispe', '918098992', 'la_victoria', 'Jr garcia naranjo nmr 1240 entre parinacocha', NULL, 'casa', 'PARA MI ESPOSA\r\nUn feliz Dia mi Princesa\r\nEres un regalo de Dios \r\nSigamos  juntos de la mano de Dios hasta llegar a la meta. \r\nTe Amo mucho 💜', 25.00, 'bcp', 'entregado', 'listo', 0, '2026-02-13 21:02:31', '2026-02-13 21:54:20', 2, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-13 20:35:06', '2026-02-14 02:58:16'),
(48, 'Johan Chauca', '943955117', '2026-02-13', '2026-02-14', 'manana', NULL, 'Gloria Bucheli', '995031814', 'ate', 'prolongacion los ajenjos 125 depto. 205', NULL, 'casa', 'TE AMO PRECIOSA\r\nFELIZ DIA DEL AMOR\r\nATT.\r\nGB', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 02:07:03', '2026-02-14 02:07:08', 1, 9, 'Luis Enrique', '944475324', NULL, 'Recibió el señor David', '2026-02-14 14:36:03', 'en_ruta', '2026-02-13 20:48:52', '2026-02-14 14:36:03'),
(49, 'Renzo', '981541936', '2026-02-13', '2026-02-14', 'manana', NULL, 'carla casella', '922720548', 'san_miguel', 'calle Manco segundo 145 dpto. 702C', NULL, 'casa', 'Este San Valentín quiero agradecerte por amar bonito, en paz y hacerlo tan sencillo.\r\n¡Feliz día de San Valentín!\r\nMi amor ❤️', 25.00, 'interbank', 'entregado', 'listo', 0, '2026-02-14 02:11:18', '2026-02-14 02:11:22', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 13:57:37', 'en_ruta', '2026-02-13 20:55:19', '2026-02-14 13:57:37'),
(50, 'GIAN CARLO FLORES CACERES', '99999999', '2026-02-13', '2026-02-14', 'manana', NULL, 'beatriz matencio najarro', '997461467', 'miraflores', 'Nueva Direccion: Av, 28 de Julio 887, Torre A, Dpto 1507, Miraflores', NULL, 'casa', 'TE AMO, porque entendí que, aunque no te necesite para vivir, quiero que cada día estes a mi lado. TE EXTRAÑO, ¡FELIZ SAN VALENTÍN! \r\n\r\nGIAN CARLO FLORES CACERES', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:48:38', '2026-02-14 07:50:33', 4, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 13:05:23', 'en_ruta', '2026-02-13 21:00:49', '2026-02-14 13:05:23'),
(51, 'johan chauca', '943955117', '2026-02-13', '2026-02-14', 'manana', NULL, 'maribel correa', '964657000', 'lince', 'Jiron Crespo y Castillo 3274, Mirones bajo', NULL, 'casa', 'UN DETALLE ESPECIAL para MI PERSONA ESPECIAL\r\ncon la alegría y agradecimiento de disfrutar este día juntos.\r\ny en compañia de nuestro amor hecho persona\r\nFELIZ DIA DEL AMOR, mi Reyna\r\n\r\nte ama:  Johan', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 02:11:41', '2026-02-14 02:11:44', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Personalmente', '2026-02-14 13:46:11', 'en_ruta', '2026-02-13 21:28:36', '2026-02-14 13:46:11'),
(52, 'mathias sanchez', '964306164', '2026-02-13', '2026-02-14', 'manana', 'tocar timbre', 'mathias sanchez', '964306164', 'surquillo', 'inca 1192 surquillo ( tocar timbre)', NULL, 'casa', 'Feliz día del administrador 💜', 15.00, 'yape', 'entregado', 'listo', 0, '2026-02-13 22:03:04', '2026-02-13 22:03:20', 4, 7, 'Yesenia Aguirre', '932951056', NULL, 'Todo bien', '2026-02-14 12:20:43', 'en_ruta', '2026-02-13 21:57:36', '2026-02-14 12:20:43'),
(53, 'quintana', '989208168', '2026-02-12', '2026-02-14', 'manana', NULL, 'Farieth Moreno', '989208168', 'san_isidro', 'Avenida Jorge Basadre Grohmann 367', NULL, 'casa', 'Un día más a tu lado amor. Feliz día preciosa y por más días contigo. Gracias por esta vida juntos y por lo afortunados que somos. Te amo infinito 🤍', 15.00, 'interbank', 'entregado', 'listo', 0, '2026-02-14 04:12:34', '2026-02-14 04:15:37', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 12:37:39', 'en_ruta', '2026-02-13 22:04:30', '2026-02-14 12:37:39'),
(54, 'anonimo', '+51 992 369 179', '2026-02-13', '2026-02-14', 'manana', 'entregar de 7am a 9:30 am', 'Aylin Neyra Miranda', '918257773', 'villa_el_salvador', 'Parque Industrial, Mz.V, Lt.11, Villa EL Salvador 15816. Villa el Salvador', 'https://share.google/U2UXqbWbNl6Hu7M6G', 'casa', '\"Gracias por ser mi lugar preferido en el mundo amor de mi vida ❤️.  ¡ Feliz primer San Valentín !', 30.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 09:47:53', '2026-02-14 09:48:32', 4, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 16:10:49', 'en_ruta', '2026-02-13 22:08:24', '2026-02-14 16:10:49'),
(55, 'lucero', '929159042', '2026-02-13', '2026-02-14', 'manana', NULL, 'lucero', '929159042', 'lima', 'calle cesar vallejo 591, lima', NULL, 'casa', 'Feliz día', 20.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 09:47:59', '2026-02-14 09:48:34', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Rsposo', '2026-02-14 13:35:20', 'en_ruta', '2026-02-13 22:24:24', '2026-02-14 13:35:20'),
(56, 'johan chauca', '995031814', '2026-02-13', '2026-02-14', 'manana', NULL, 'miryan juarez', '995031814', 'jesus_maria', 'avenida Garzon 1265', NULL, 'casa', 'FELIZ DIA DEL AMOR\r\n          ATT.\r\n                    G', 11.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:51:53', '2026-02-14 07:54:02', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Personalmente', '2026-02-14 19:08:16', 'reprogramado', '2026-02-13 22:33:51', '2026-02-14 19:08:16'),
(57, 'newstor valdivia', '943546986', '2026-02-13', '2026-02-14', 'manana', NULL, 'newstor valdivia', '943546986', 'lima', 'calle eugenia paredes 2337', NULL, 'casa', 'Feliz dia amorcito, te deseamos Enzito e Ivan', 0.00, 'payum', 'entregado', 'listo', 0, '2026-02-14 02:14:21', '2026-02-14 02:14:26', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Esposo', '2026-02-14 13:59:50', 'en_ruta', '2026-02-13 22:49:55', '2026-02-14 13:59:50'),
(58, 'juan carlos', '+51 990 034 988', '2026-02-13', '2026-02-14', 'manana', 'altura del colegio trilce de santa anita / casa primer piso', 'ariana fernandez', '950102513', 'santa_anita', 'Coperativa viña san francisco manzana F lote 21 , santanita.', 'https://www.google.com/maps/place/12%C2%B001\'55.4%22S+76%C2%B057\'08.8%22W/@-12.0320412,-76.9550071,17z/data=!3m1!4b1!4m4!3m3!8m2!3d-12.0320412!4d-76.9524322?hl=es&entry=ttu&g_ep=EgoyMDI2MDIxMS4wIKXMDSoASAFQAw%3D%3D', 'casa', 'Feliz san valentin , mi reyna.\r\n\r\nNo importa que tan lejos este , siempre me acercare de cualquier forma.\r\n\r\nTe amo ♡', 30.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 04:13:26', '2026-02-14 04:15:43', 4, 9, 'Luis Enrique', '944475324', NULL, 'Recibió la señorita Ariana', '2026-02-14 16:01:35', 'en_ruta', '2026-02-13 23:39:26', '2026-02-14 16:01:35'),
(59, 'anonimo', '+51 921 138 185', '2026-02-13', '2026-02-14', 'manana', NULL, 'María del Pilar', '925221493', 'santiago_surco', 'Pasaje César Vilca Mz A lot 8 surco', 'https://maps.app.goo.gl/Be5wSofPG24ZuMLR7?g_st=com.google.maps.preview.copy', 'casa', 'Así como el señor Darcy aprendió a dejar de lado el orgullo para mostrar la nobleza de su alma, usted siempre ha sabido tratarme con respeto, dulzura y consideración. Y como Elizabeth valoró la sinceridad y el carácter auténtico, yo valoro profundamente su forma tan genuina de brindar afecto.\r\nFeliz día del amor y la amistad!', 18.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 09:48:04', '2026-02-14 09:48:38', 4, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 16:09:35', 'en_ruta', '2026-02-14 00:14:17', '2026-02-14 16:09:35'),
(60, 'edgador zamora', '996486634', '2026-02-13', '2026-02-14', 'manana', NULL, 'consuelo diaz cordova', '996481488', 'san_borja', 'Av. san borjas norte 412, ref ( entre la Av. las artes sur  san borjas norte', NULL, 'oficina', '“Han pasado ya varios años que hemos iniciado nuestra relación, tal ves no sea perfecta pero nuestra perseverancia, dedicación y sobre todo la decisión de amarnos nos ha permitido seguir juntos, te Amo Patita, Feliz Día”', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 09:48:07', '2026-02-14 09:48:42', 2, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 20:05:53', 'en_ruta', '2026-02-14 00:27:54', '2026-02-14 20:05:53'),
(61, 'jesus palomares grados', '948452016', '2026-02-13', '2026-02-14', 'tarde', NULL, 'andrea huaman lujan', '994187176', 'santa_anita', 'Av francisco bolognesis 1093', NULL, 'casa', 'En este día dedicado al amor quiero recordarte que eres mi alegría, mi amor constante y mi futuro soñado, gracias por ser parte de mi vida, TE AMO ANDREA ♥️', 30.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 04:14:39', '2026-02-14 04:15:54', 2, 9, 'Luis Enrique', '944475324', NULL, 'Recibió la misma señorita', '2026-02-14 15:17:48', 'en_ruta', '2026-02-14 00:32:55', '2026-02-14 15:17:48'),
(62, 'jose manuel', '982017029', '2026-02-13', '2026-02-14', 'manana', NULL, 'Sabrina Vasquez', '941135304', 'ancon', 'centrro comercial minka puerta 3 callao', NULL, 'casa', NULL, 30.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 09:48:11', '2026-02-14 09:48:45', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-14 00:43:09', '2026-02-14 17:45:56'),
(63, 'marcos', '+51 999 972 573', '2026-02-13', '2026-02-14', 'manana', 'de 12 a 5pm', 'mily sandoval', '+51 999 972 573', 'santiago_surco', '_Jr hernando de lavalle y pardo 140, Surco (casa)', NULL, 'casa', 'Te agradezco por estar a mi lado,,siempre la compañera de mi vida. \r\nFeliz día Milicita.......Marcos', 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:52:07', '2026-02-14 07:54:11', 4, 10, 'fiorella sanchez', '982767685', NULL, '.', '2026-02-14 15:05:20', 'en_ruta', '2026-02-14 01:29:02', '2026-02-14 15:05:20'),
(64, 'kimen alex', '963835734', '2026-02-13', '2026-02-14', 'tarde', NULL, 'alejandra olortigue tello', '923044506', 'independencia', 'JR.celesdin 182, independecia', NULL, 'casa', 'nuestro futuro aquí en la tierra depende de nosotros, pero nuestra eternidad del padre celestial <3', 30.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:49:14', '2026-02-14 07:50:35', 2, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-14 01:54:51', '2026-02-16 13:30:43'),
(65, 'siu tong', '936819963', '2026-02-13', '2026-02-13', 'tarde', NULL, 'Roxana Gaudry', '936821808', 'pueblo_libre', 'Jiron Santiago Wagner 2569', NULL, 'casa', 'Feliz San Valentín amorcito! Que nuestro amor perdure siempre 🙂', 15.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 03:08:14', '2026-02-14 03:08:21', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 02:00:38', '2026-02-14 03:08:21'),
(66, 'carla', '+19543933252', '2026-02-13', '2026-02-14', 'manana', NULL, 'luisa Herrera', '987861551', 'san_miguel', 'Avenida del pacifico 135 depto. 102', NULL, 'casa', 'Para mi amada esposa, Carla\r\n\r\nDesde que llegaste a mi vida, todo cambió para bien. Eres mi paz en los días difíciles, mi alegría en los momentos felices y la razón por la que cada día quiero ser mejor.\r\n\r\nTu amor me levanta, me sana y me hace sentir en casa, sin importar la distancia. No necesito un mundo perfecto, solo te necesito a ti.\r\n\r\nHoy y siempre te elijo, te valoro y te amo con todo mi corazón.\r\n\r\n¡Feliz Día de San Valentín!\r\n\r\nCon todo mi amor, tu esposo\r\nJordan\r\n14 de febrero de 2026', 25.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 02:37:33', '2026-02-14 02:38:15', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 14:09:20', 'en_ruta', '2026-02-14 02:20:57', '2026-02-14 14:09:20'),
(67, 'bryan', '986825774', '2026-02-13', '2026-02-14', 'manana', NULL, 'Karla Valencia', '919654350', 'pueblo_libre', 'Cipriano dulanto 541 dpto. 203A', NULL, 'casa', '“Feliz San Valentin Mi amor, espero que en este dia disfrutes todo el amor que siempre te dare, recuerda que siempre te amaré por toda la vida, mi princesa”', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 07:53:26', '2026-02-14 07:54:13', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Conserge', '2026-02-14 14:23:59', 'en_ruta', '2026-02-14 02:23:37', '2026-02-14 14:23:59'),
(68, 'alfredo Davalos', '983407372', '2026-02-13', '2026-02-14', 'manana', NULL, 'Rosemary Amesquita', '969373426', 'san_martin_porres', 'jiron German stiglich 2029', NULL, 'casa', 'Cuando abro mis ojos doy gracias a Dios, no solo por el nuevo dia, sino por el milagro sencillo de despertar con la persona que más amo a mi lado\r\n\r\nPor qué hay mañanas que son bendición  y otras como esta, son respuesta a mis oraciones', 35.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 02:35:32', '2026-02-14 02:35:34', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-14 02:27:47', '2026-02-16 13:30:38'),
(69, 'jose alejandro', '986689732', '2026-02-13', '2026-02-14', 'manana', NULL, 'Ana Maria Naseli', '965361624', 'jesus_maria', 'Avenida General Garzon 734 dpto. 401A', NULL, 'casa', 'FELIZ DIA DEL AMOR NAGITA, QUE SEAN MUCHOS MAS COMO FAMILIA, TE AMO !', 20.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 09:48:15', '2026-02-14 09:48:48', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Personalmente', '2026-02-14 12:49:14', 'en_ruta', '2026-02-14 02:30:05', '2026-02-14 12:49:14'),
(70, 'mi vida eres tu', '953564975', '2026-02-13', '2026-02-14', 'manana', NULL, 'daysy Lazano', '943043086', 'comas', 'Jiron Bernardo monteagudo 204 dpto. 402', NULL, 'casa', 'Feliz Día de San Valentín Esposa Mía y a pesar de estar lejos de ti, siento cada día estar más enamorado de ti. Eres mi inspiración y se siento amado a tu lado. Ya falta poco para estar juntos y Te Ama con locura tú siempre Esposo, Heyseer.', 35.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 09:48:18', '2026-02-14 09:48:51', 1, 1, 'Alejandro Canales', '990036869', NULL, NULL, NULL, NULL, '2026-02-14 02:32:39', '2026-02-16 13:30:33'),
(71, 'nat', '992655004', '2026-02-13', '2026-02-14', 'manana', 'de 12 a 5 pm / local puerta calle', 'deysi mechan', '929188892', 'lima', 'av tacna 572', NULL, 'casa', 'Vi esta flor y pensé en ti, por qué eres bonita.\r\nSonríe', 20.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 04:14:08', '2026-02-14 04:15:49', 4, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Personalmente', '2026-02-14 18:10:26', 'reprogramado', '2026-02-14 03:03:12', '2026-02-14 18:10:26'),
(72, 'oscar', '942450199', '2026-02-14', '2026-02-14', 'manana', NULL, 'ana caldero toro', '953670246', 'miraflores', 'calle gonzales prada 165, dpto 702 ( refenrecia campu palance )', NULL, 'casa', 'Feliz San Valentin, Paye!!', 30.00, 'bcp', 'entregado', 'listo', 0, '2026-02-14 13:46:18', '2026-02-14 13:46:37', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok espera 5 minutos', '2026-02-14 17:10:11', 'en_ruta', '2026-02-14 13:37:26', '2026-02-14 17:10:11'),
(74, 'jose luis', '992254283', '2026-02-14', '2026-02-14', 'manana', NULL, 'margot mendoza molina', '998174157', 'la_victoria', 'Los Jacintos 125 Urb. Balconcillos La Victoria . Alt. De la cuadra 4 de la Avenida México.', NULL, 'casa', 'Feliz San Valentín Mi Osita bella . Contigo entendí que el amor verdadero no se busca, se reconoce desde el primer latido.', 25.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 15:01:17', '2026-02-14 15:23:53', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Dirección incorrecto se entrego pedido', '2026-02-14 18:52:41', 'en_ruta', '2026-02-14 14:52:49', '2026-02-14 18:52:41'),
(75, 'joaquin', '934809674', '2026-02-14', '2026-02-14', 'manana', NULL, 'alexandra montes', '991889884', 'breña', 'Admision niño de breña Avenida Brasil', 'https://maps.google.com/maps/place//data=!4m2!3m1!1s0x9105c9002114747d:0xeadda11293cb1017?entry=s&sa=X&ved=2ahUKEwjdgOuMnNmSAxXSqJUCHS75JRUQ4kB6BAgEEAA&hl=es', 'oficina', 'Feliz San Valentín Mi amor!! \r\nEspero verte siempre sonreír \r\nTe quiero mucho !!', 20.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 15:01:20', '2026-02-14 15:05:31', 1, 8, 'Juan Carlos Tafur', '942130654', NULL, 'Personalmente', '2026-02-14 18:06:56', 'en_ruta', '2026-02-14 15:00:29', '2026-02-14 18:06:56'),
(76, 'ciente anonimo', '932988132', '2026-02-14', '2026-02-14', 'manana', NULL, 'jahaira jazmin canales', '994238532', 'la_victoria', 'paseo la republica 1835/ concensionario kia AUTOLAND', NULL, 'casa', 'Para mi Jhaz 💖\r\nFeliz San Valentín, mi amor.\r\nHoy quiero recordarte lo afortunado que soy de tenerte en mi vida. Ya son más de dos años caminando juntos, creciendo, aprendiendo y construyendo nuestro propio hogar. Y si algo tengo claro, es que no cambiaría ni un solo día a tu lado.\r\nJhaz, no solo eres mi pareja, eres mi compañera, mi paz después de un día difícil, mi risa favorita y el lugar donde siempre quiero volver. Vivir contigo me ha enseñado que el amor no solo se dice… se demuestra en cada detalle, en cada abrazo, en cada “buenos días” y en cada noche compartida.\r\nGracias por elegirme todos los días. Gracias por tu paciencia, tu cariño y por hacer que nuestro hogar se sienta lleno de amor.\r\nTe amo más de lo que las palabras pueden explicar.\r\nY si estos dos años han sido hermosos, no imagino todo lo increíble que nos espera juntos.\r\nSiempre tú y yo, mi Jhaz 💞', 25.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 16:08:49', '2026-02-14 16:09:18', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 17:29:20', 'pendiente', '2026-02-14 15:54:21', '2026-02-14 17:29:20'),
(77, 'Juan Veliz', '959182533', '2026-02-14', '2026-02-14', 'manana', NULL, 'jonathan Barreto', '940440463', 'la_victoria', 'jiron antonio Raimondi', 'https://www.google.com/maps/place/12%C2%B003\'26.5%22S+77%C2%B000\'49.4%22W/@-12.0573674,-77.0163022,17z/data=!3m1!4b1!4m4!3m3!8m2!3d-12.0573674!4d-77.0137273?hl=es&entry=ttu&g_ep=EgoyMDI2MDIxMS4wIKXMDSoASAFQAw%3D%3D', 'casa', 'sin dedicatoria', 0.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 16:08:55', '2026-02-14 16:09:21', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Dirección incorrecta pero está entregado', '2026-02-14 18:00:18', 'en_ruta', '2026-02-14 15:56:54', '2026-02-14 18:00:18'),
(78, 'JAN VELIZ', '959182533', '2026-02-14', '2026-02-14', 'manana', NULL, 'flor depaz', '936931733', 'la_victoria', 'jiron jauregui 523', NULL, 'casa', 'No existen palabras que puedan describir todo lo que siento por ti. Que estas preciosas flores sean un complemento a tu belleza.', 20.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 16:09:05', '2026-02-14 16:09:28', 1, 7, 'Yesenia Aguirre', '932951056', NULL, 'Ok', '2026-02-14 18:19:08', 'en_ruta', '2026-02-14 16:02:01', '2026-02-14 18:19:08'),
(79, 'richie orozco', '992148873', '2026-02-14', '2026-02-14', 'manana', NULL, 'betzabeth', '908799892', 'santiago_surco', 'AV AYACUCHO 920 SURCO \r\nEs una tienda de motos eléctricas , se llama SHEEPBUSTER', NULL, 'oficina', 'PARA LA MÁS BONITA \r\nMI SÚPER CHICA , MI SÚPER MAMÁ ! I LOVE YOU ! FELIZ DIA ❤️❤️', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-14 17:33:46', '2026-02-14 17:33:54', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 17:31:28', '2026-02-16 13:30:29'),
(80, 'CD Eddi garcia', '951300093', '2026-02-14', '2026-02-14', 'manana', NULL, 'karol genny diaz', '991338217', 'san_martin_porres', 'Av. Malecón Rímac 1996, San Martín de Porres, 15106, LM, PE', NULL, 'casa', 'Cualquier Momento A Tu Lado Esperfecto Para Ser Feliz, Porque No Es El Tiempo Ni El Lugar, Eres Tu', 35.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 18:12:10', '2026-02-14 18:12:22', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 17:50:31', '2026-02-16 13:30:25'),
(81, 'tomas morales', '961826327', '2026-02-14', '2026-02-14', 'manana', NULL, 'angelica maria illapama', '922230439', 'lima', 'jiron conde de las vega 996', NULL, 'casa', 'Eres unica  y especial Daisuki desu, feliz día de la amistad y del amor.', 20.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 18:12:16', '2026-02-14 18:12:25', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 18:04:01', '2026-02-16 13:30:20'),
(83, 'sanme', '953501678', '2026-02-14', '2026-02-14', 'tarde', NULL, 'patricia', '989168493', 'la_victoria', 'calle jose farias rios 191', NULL, 'casa', 'Feliz día del amor para los reinas de la casa! Este año es diferente porque tenemos una nueva integrante de la familia, a la niña de nuestros ojos, a Rafita ❤️ Solo decirles que voy a poner de mi parte al 100% para poder lograr todos nuestros objetivos, crecer como familia y brindarles mucho amor para que sean felices siempre!', 20.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 18:45:47', '2026-02-14 18:51:43', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 18:18:04', '2026-02-16 13:30:16'),
(84, 'oscar jamas  chacceri', '977839215', '2026-02-14', '2026-02-14', 'tarde', NULL, 'oscar', '977839215', 'carabayllo', 'Mz m2 lt 48 santo domingo 6ta etapa  distrito carbayllo', NULL, 'casa', 'feliz dia de san valentin,Gracias amor mio  por llenar mis días de risas, amor y ternura, te amo amor mio😍', 40.00, 'plin', 'entregado', 'listo', 0, '2026-02-14 19:20:16', '2026-02-14 19:20:20', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 19:18:50', '2026-02-16 13:25:22'),
(85, 'j torres', '981550874', '2026-02-14', '2026-02-14', 'manana', NULL, 'yoani quispe', '912474481', 'la_victoria', 'Avenida Javier prado este 1501 dpto. 301', NULL, 'casa', NULL, 20.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 19:34:57', '2026-02-14 19:47:02', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 19:19:50', '2026-02-16 13:25:12'),
(86, 'J Torres', '981550874', '2026-02-14', '2026-02-14', 'manana', NULL, 'elena Mamani', '981315123', 'santiago_surco', 'Jiron Trinitarias 270', NULL, 'casa', NULL, 20.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 19:35:02', '2026-02-14 19:47:10', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 19:21:28', '2026-02-16 13:24:58'),
(87, 'benjamin peña', '966083511', '2026-02-14', '2026-02-14', 'manana', NULL, 'jessi nathalie', '934356687', 'los_olivos', 'calle rio chicama 5685', NULL, 'casa', NULL, 30.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-14 19:35:32', '2026-02-14 19:47:14', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 19:32:15', '2026-02-16 13:24:43'),
(88, 'dam hnt', '966261626', '2026-02-14', '2026-02-14', 'manana', NULL, 'ingrid silvana', '992956355', 'callao', 'Mz e7 lt. 16 mi peru callao', NULL, 'casa', NULL, 30.00, 'yape', 'no_entregado', 'listo', 0, '2026-02-14 19:46:48', '2026-02-14 19:47:26', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 19:35:57', '2026-02-16 13:25:06'),
(89, 'tania', '913947574', '2026-02-14', '2026-02-14', 'manana', NULL, 'yoisi tello', '979219485', 'ate', 'X4C6+CMH, ate', NULL, 'casa', NULL, 0.00, 'izipay', 'entregado', 'listo', 0, '2026-02-14 19:46:53', '2026-02-14 19:47:29', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-14 19:43:10', '2026-02-16 13:24:51'),
(90, 'raul', '+17023021204', '2026-02-16', '2026-02-16', 'manana', NULL, 'Diana Aquino', '988699868', 'lima', 'XX3G+GH8,LIMA', 'https://maps.google.com/?q=-12.046222,-77.023544', 'oficina', 'Gracias por Los momentos maravillosos que me regalas con Amor tu V.R', 25.00, 'izipay', 'entregado', 'listo', 0, '2026-02-16 15:38:05', '2026-02-16 15:38:12', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-16 15:08:23', '2026-02-16 17:22:19'),
(91, 'jesus', '943882488', '2026-02-16', '2026-02-16', 'manana', NULL, 'Milaqgro Obrezo', '943882488', 'magdalena', 'avenida sanchez carrion 166 dpto. 802', NULL, 'casa', 'km 25…y vamos por más….te amo!!!', 20.00, 'yape', 'entregado', 'listo', 0, '2026-02-16 15:38:08', '2026-02-16 15:41:33', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-16 15:31:32', '2026-02-16 16:19:53'),
(92, 'dennis', '980446179', '2026-02-18', '2026-02-18', 'manana', NULL, 'nancy Gonzales', '987421891', 'villa_el_salvador', 'sector 1 grupo 17', 'https://maps.app.goo.gl/kABaaSNbQSECX6Pr7?g_st=iw', 'casa', NULL, 30.00, 'yape', 'entregado', 'listo', 0, '2026-02-18 15:41:36', '2026-02-18 16:23:49', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-18 14:44:18', '2026-02-18 18:41:24'),
(93, 'dana ross', '968095082', '2026-02-18', '2026-02-20', 'tarde', NULL, 'dana ross', '968095082', 'surquillo', 'recoje en central', NULL, 'oficina', NULL, 0.00, 'yape', 'entregado', 'listo', 0, '2026-02-20 17:41:58', '2026-02-20 18:18:43', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-18 19:44:28', '2026-02-21 15:10:10'),
(94, 'Andrea Lozada', '947275559', '2026-02-19', '2026-02-21', 'manana', 'chocolate ferrero roche y 1 globo de feliz cumpleaños', 'Andrea Lozada', '974275559', 'san_juan_lurigancho', 'Jiron las Grosellas 1030', NULL, 'casa', '\"Feliz cumpleaños, Martitha. Hoy celebro no solo un año más de tu vida, sino el regalo inmenso de tu presencia en la mía. Que Dios y la Virgen guíen cada uno de tus pasos, te rodeen de salud y protejan siempre ese corazón tan noble que tienes.\r\n​Te envío estas rosas como símbolo de una amistad que florece con el tiempo y que valoro profundamente. Gracias  por tu compañía y por compartir un año más de camino conmigo. Que este nuevo ciclo esté lleno de amor y de sueños cumplidos. ¡Te amo amiga!\"', 30.00, 'izipay', 'entregado', 'listo', 0, '2026-02-21 15:05:30', '2026-02-21 15:40:37', 1, 11, 'jose luis', '942349803', NULL, NULL, NULL, NULL, '2026-02-19 14:50:35', '2026-02-21 15:40:37'),
(95, 'fghjjv', '941260085', '2026-02-20', '2026-02-20', 'manana', NULL, 'laura moscol', '979818786', 'san_isidro', 'Juan de Arona 151', NULL, 'casa', NULL, 10.00, 'izipay', 'entregado', 'listo', 0, '2026-02-20 17:41:50', '2026-02-20 18:18:49', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-20 13:28:09', '2026-02-20 18:18:59'),
(96, 'johan chauca', '943955117', '2026-02-20', '2026-02-22', 'manana', NULL, 'Raisa Correa', '999220202', 'san_miguel', 'Jiron Mariscal Ramos Castilla 520 dpto. A202.', NULL, 'casa', NULL, 25.00, 'yape', 'entregado', 'listo', 0, '2026-02-21 16:27:02', '2026-02-21 21:31:50', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-20 20:38:31', '2026-02-23 16:27:15');
INSERT INTO `reporte_entregas` (`id`, `nombre_cliente`, `telefono_cliente`, `fecha_compra`, `fecha_entrega`, `turno_entrega`, `observacion`, `nombre_destinatario`, `telefono_destinatario`, `distrito`, `direccion_destinatario`, `enlace_ubicacion`, `tipo_ubicacion`, `dedicatoria`, `costo_delivery`, `metodo_pago`, `estado`, `estado_produccion`, `es_urgente`, `produccion_iniciada_en`, `produccion_completada_en`, `created_by`, `conductor_id`, `nombre_conductor`, `telefono_conductor`, `foto_entrega`, `observacion_conductor`, `fecha_confirmacion`, `estado_anterior`, `created_at`, `updated_at`) VALUES
(97, 'Juan Mayo', '+34637193919', '2026-02-21', '2026-02-21', 'tarde', NULL, 'akeemy mayo Marchena', '+51 969 501 863', 'la_victoria', 'Galeria Gama\r\nsemisotano\r\n041 Gamarra la Victoria', NULL, 'oficina', NULL, 21.00, 'izipay', 'entregado', 'listo', 0, '2026-02-21 19:28:06', '2026-02-21 21:26:40', 1, 11, 'jose luis', '942349803', NULL, NULL, NULL, NULL, '2026-02-21 19:18:44', '2026-02-21 23:37:03'),
(98, 'Luis Angel', '996006943', '2026-02-21', '2026-02-21', 'tarde', NULL, 'Kiara Vela', '990997889', 'san_borja', 'Fray Angelico 279.', NULL, 'casa', NULL, 18.00, 'yape', 'entregado', 'listo', 0, '2026-02-21 21:26:42', '2026-02-21 23:37:10', 1, 11, 'jose luis', '942349803', NULL, NULL, NULL, NULL, '2026-02-21 20:21:35', '2026-02-21 23:37:10'),
(99, 'edwin', '990 336 012', '2026-02-20', '2026-02-23', 'manana', NULL, 'NADIESKA DEIDAMIA GOICOCHEA JALCA', '991 766 895', 'miraflores', 'Sede Central MINJUSDH: Calle Scipión Llona N° 350, Miraflores, Lima.\r\nAuditorio Central del MINJUSDH', NULL, 'oficina', 'rosas color lila, rosadas, amrillas, fucsias, blancas', 15.00, 'bcp', 'entregado', 'listo', 0, '2026-02-21 21:31:57', '2026-02-23 16:27:00', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-21 21:30:43', '2026-02-23 16:27:08'),
(100, 'rossana ciccia', '994226352', '2026-02-23', '2026-02-24', 'manana', NULL, 'Ita Ridella', '013724020', 'san_borja', 'Avenida del Pinar 412, Chacarilla del Estanque', NULL, 'casa', NULL, 15.00, 'yape', 'entregado', 'listo', 0, '2026-02-23 19:41:34', '2026-02-23 20:15:01', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-23 19:41:03', '2026-02-24 17:11:15'),
(101, 'ej de rita', '+34681262397', '2026-02-24', '2026-02-24', 'manana', 'peluche de perrito pequeño', 'Katheryn Hidalgo', '98059706', 'ate', 'Avenida los ingenieros  Mz. E, Lt. 11', NULL, 'oficina', NULL, 40.00, 'efectivo', 'entregado', 'listo', 0, '2026-02-24 17:10:47', '2026-02-24 17:10:53', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-24 16:57:43', '2026-02-24 17:45:50'),
(102, 'diego TMM', '961499562', '2026-02-24', '2026-02-25', 'manana', 'rosas rosadas', 'Solangel Carvajal', '975311917', 'san_isidro', 'Calle 1 Oeste 061', NULL, 'casa', NULL, 24.00, 'izipay', 'pendiente', 'listo', 0, '2026-02-25 13:45:16', '2026-02-25 13:45:20', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-24 16:59:39', '2026-02-25 13:45:20'),
(103, 'karin quijada', '937009402', '2026-02-24', '2026-02-24', 'tarde', NULL, 'karin quijada', '937009402', 'jesus_maria', 'Avenida Garzon 87 dept. 201', NULL, 'casa', NULL, 3.00, 'izipay', 'en_ruta', 'listo', 0, '2026-02-24 17:10:50', '2026-02-24 21:05:14', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-24 17:08:32', '2026-02-24 21:06:09'),
(104, 'tori', '976564025', '2026-02-24', '2026-02-24', 'manana', NULL, 'rosa torres de nContreras', '952664483', 'san_juan_lurigancho', 'Jiron los Medicos 3753', NULL, 'casa', NULL, 30.00, 'izipay', 'pendiente', 'listo', 0, '2026-02-24 21:05:17', '2026-02-24 21:05:20', 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-24 19:57:18', '2026-02-24 21:05:20'),
(105, 'Aaron', '998809922', '2026-02-24', '2026-02-25', 'tarde', NULL, 'Maria Echegoyen', '941573341', 'lima', 'Jiron zorritos 1203 (Puerta Principal del MTC)', NULL, 'oficina', NULL, 20.00, 'yape', 'pendiente', 'pendiente', 0, NULL, NULL, 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-25 13:42:37', '2026-02-25 13:45:11'),
(106, 'cristian palomino', '988653793', '2026-02-24', '2026-02-28', 'manana', NULL, 'cristian palomino', '988653793', 'san_isidro', 'Calle Juan Norberto Elespurru 535 dpto. 1205', NULL, 'casa', NULL, 25.00, 'izipay', 'pendiente', 'pendiente', 0, NULL, NULL, 1, NULL, '', '', NULL, NULL, NULL, NULL, '2026-02-25 13:44:54', '2026-02-25 13:44:54');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('B7MDZyZpUJKehtJp4GVbqo5anc62i9NuH5imoQsQ', NULL, '54.39.104.60', 'Mozilla/5.0 (Windows NT 10.0; rv:73.0) Gecko/20100101 Firefox/73.0', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiaUM3OXRqWktRQnJxMm1meVpITmppeG01WmNTN1cyWGtMd0h5VkRjNiI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MjU6Imh0dHA6Ly9hbWF0aXN0YS5jb20vbG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1772110012),
('BJ5GH4Pix4FoIJN73R1smRO28EQXXaAQDPwhIpLw', NULL, '149.56.160.187', 'Mozilla/5.0 (compatible; Dataprovider.com)', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiTEhGeXduaHNWbDZiSVIyaGVxTUZ6NURwSlJZdFExbFA0NVpBSkpVUyI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MzA6Imh0dHBzOi8vd3d3LmFtYXRpc3RhLmNvbS9sb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1772115983),
('BOEH9XtaHyZzdQYvtNAhUutdXcBpvtPVllABKT7m', 1, '38.25.22.251', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoieUFwMnRjRG9TRXJuUzJXS0xvOG9MUThXa1h4WHFBc0EweTlTeXRKSCI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjE6e3M6MzoidXJsIjtzOjYxOiJodHRwczovL2FtYXRpc3RhLmNvbS9wcm9kdWNjaW9uP2ZlY2hhPTIwMjYtMDItMjgmdHVybm89bWFuYW5hIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MTt9', 1772123953),
('Cp0hP8MixwB4hwO3NJfWEaZcYecMcFJwocZgZNDA', NULL, '149.56.160.187', 'Mozilla/5.0 (compatible; Dataprovider.com)', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiNWdtaVRDZ2ZpU3hSMjZVRWJibXNjMkZKQjU2emtKV2YybDN5aGJ4biI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyNDoiaHR0cHM6Ly93d3cuYW1hdGlzdGEuY29tIjt9czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MjQ6Imh0dHBzOi8vd3d3LmFtYXRpc3RhLmNvbSI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1772116004),
('D9Kj7cUxLjfNFUERYd8xHSYXAqBqaCV3E1Tszx8u', NULL, '149.56.160.187', 'Mozilla/5.0 (compatible; Dataprovider.com)', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoib05TRmdLUkMzZ3lVM2xqSlo3UWtCQ2ZiaGNRdnNpTVBXMmhaSjNyNSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyMzoiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20iO31zOjk6Il9wcmV2aW91cyI7YToxOntzOjM6InVybCI7czoyOToiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20vbG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1772116002),
('dsvEJGfY36tNfY0jAIhhkzGUrNG6Mt6wI4vIy42J', NULL, '104.28.115.85', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiUmZKbWFSQ20ycjFZdm1ZUURnMGJEQms0MU1KQzR1c3kxVEI3VzR2WCI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyMDoiaHR0cHM6Ly9hbWF0aXN0YS5jb20iO31zOjk6Il9wcmV2aW91cyI7YToxOntzOjM6InVybCI7czoyMDoiaHR0cHM6Ly9hbWF0aXN0YS5jb20iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1772121826),
('hGpfjNrBv1v2ZADk3QZdQalwu5yIeUfxF2Ubs6jP', NULL, '173.252.70.7', 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiSlBhOXZiSTJJZ251c2ZINmpGUEI3bjZDQlc2bllDeUZWWlB6M2xKTSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyMzoiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20iO31zOjk6Il9wcmV2aW91cyI7YToxOntzOjM6InVybCI7czoyMzoiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1772120958),
('KDzVVETNn3JA8iESGXJp7ChOwWerXWbA17WeweQF', NULL, '149.56.160.187', 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiQlJBcUhTaTJ6SnFMM3RsbkdtVHhJUWZwa1kyQkNkbXJSckZpQUY1diI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyMzoiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20iO31zOjk6Il9wcmV2aW91cyI7YToxOntzOjM6InVybCI7czoyOToiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20vbG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1772115986),
('lCrZT8U7EcDLnM94yIsyEWco8pdHIKoJB4rDaYDm', NULL, '69.171.230.38', 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVGpYV1d5cXhNc3NtTEZHa0hUUnJrRERIeDNBR3YyOTVFUGJCbWdLNyI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6Mjk6Imh0dHA6Ly93d3cuYW1hdGlzdGEuY29tL2xvZ2luIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1772120959),
('LsxxhqiRWacfbdkwgZJPS0dKDuI489fccsJPdGhT', NULL, '66.249.66.166', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiNVBEQ3dUckRVWnpNM09KOGE0MlM4R2JDVXhKQ0RzVXpyZjdxU0hycCI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyNDoiaHR0cHM6Ly93d3cuYW1hdGlzdGEuY29tIjt9czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MjQ6Imh0dHBzOi8vd3d3LmFtYXRpc3RhLmNvbSI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1772111699),
('m04JYhncI9D5S6md9Cop8mWghkvVQoag1xBdVe6L', NULL, '104.28.115.85', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiRlp5VlRmb25LMjVQUVRkMmdJYnpQdWRqQ3ZaQzYxbnFUZG55RUExZiI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MjY6Imh0dHBzOi8vYW1hdGlzdGEuY29tL2xvZ2luIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1772121827),
('NdWRDFW4SUp77eRHt8IbxlacnS24Kekcuvel3wQc', NULL, '54.39.104.60', 'Mozilla/5.0 (Windows NT 10.0; rv:73.0) Gecko/20100101 Firefox/73.0', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiOWV0WTVzWGZFbnh1SjJRVnh1dm1nMW9vZWVZc2E5NGg1Y0ZDbWRFSCI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoxOToiaHR0cDovL2FtYXRpc3RhLmNvbSI7fXM6OToiX3ByZXZpb3VzIjthOjE6e3M6MzoidXJsIjtzOjE5OiJodHRwOi8vYW1hdGlzdGEuY29tIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1772110005),
('OLOVFH67JUBd3ka6Y6EQW0ERlhOCIMIrZHvliZD5', NULL, '149.56.160.187', 'Mozilla/5.0 (compatible; Dataprovider.com)', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVHNkVUd0WXcxUmI4SDRQdjdhdGNxTURUUFlOcUpabW0wdUwyVEF1UCI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MzA6Imh0dHBzOi8vd3d3LmFtYXRpc3RhLmNvbS9sb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1772116004),
('qyKkEdz6usRuU2RJibjVpmYmzpbHYlpvx19iW6bE', NULL, '69.171.230.2', 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiVnJCak55c3pwWHpwSlVjb0JWRXZTNjFHR2xnVERmaFJCbnhDVE1VSiI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyMzoiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20iO31zOjk6Il9wcmV2aW91cyI7YToxOntzOjM6InVybCI7czoyMzoiaHR0cDovL3d3dy5hbWF0aXN0YS5jb20iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1772120958),
('RLoJ5LdANqLoUmdwv8E6lhbTNrOtjaMoSegoO6dX', 1, '179.6.3.75', 'Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiSWlOZE1malFId0VyWUZVbW14TFdEWnZPcmJQeURqMFBvWW1pVDhnUiI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjE6e3M6MzoidXJsIjtzOjQ4OiJodHRwczovL2FtYXRpc3RhLmNvbS9wcm9kdWNjaW9uP2ZlY2hhPTIwMjYtMDItMjYiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aToxO30=', 1772111814),
('x6d0T9ibmPUnaGkwuboxdwI5un8hAxcmlYxhuMpU', NULL, '173.252.70.30', 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoieW01eVh6OE1PTEVSUm4xYkRXT1NIR1hVR3dMZGNKZ0ZMeXlVRUNzUCI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6Mjk6Imh0dHA6Ly93d3cuYW1hdGlzdGEuY29tL2xvZ2luIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1772120958);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `rol` varchar(20) NOT NULL DEFAULT 'vendedor',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `password_changed_at` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `rol`, `email_verified_at`, `password`, `password_changed_at`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Administrador', 'amatista@gmail.com', 'admin', NULL, '$2y$12$D7ptRKWAcxeRZOlj6gNdS.GuBhqBcp5RXPoG4uonw1QgT9iQuRtey', NULL, 'cjGmy3Wd3rLEeGQGo95645OqVVzv0BuXLEJXDBPuvVw111g9HbptNFlSLAZE', '2026-02-07 20:29:27', '2026-02-07 20:29:27'),
(2, 'rachely', 'delevery@detallesamatista.com', 'vendedor', NULL, '$2y$12$WCNIhUiyCyst/tsZxOx2cu9ruU33eFLz.Uuca8wwTe7UZTTdVkROu', NULL, NULL, '2026-02-07 20:58:00', '2026-02-09 19:42:18'),
(3, 'Eneas', 'detallesamatista01@gmail.com', 'produccion', NULL, '$2y$12$5vWIy8/rQt43dfS5ctGUjua2z6.stHZOu9J6eh.CsMW6WQj7p3N/i', NULL, NULL, '2026-02-09 16:18:20', '2026-02-16 15:59:50'),
(4, 'yamile', 'detallesamatista86@gmail.com', 'vendedor', NULL, '$2y$12$inZgqXwe5XPfnKkNy9ffyeQbSPtHfxxCO3PCzmevLP.FDMmbSjl3O', NULL, NULL, '2026-02-09 16:19:25', '2026-02-09 16:19:25'),
(5, 'Tito', 'tsaune@icloud.com', 'produccion', NULL, '$2y$12$EGlhGyyXR9wl1M4VHiFvIOor7YqUyhrSEtyssiLgv9IO7nwkE8Try', NULL, NULL, '2026-02-13 17:19:55', '2026-02-13 17:19:55');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditoria`
--
ALTER TABLE `auditoria`
  ADD PRIMARY KEY (`id`),
  ADD KEY `auditoria_modelo_registro_id_index` (`modelo`,`registro_id`),
  ADD KEY `auditoria_user_id_index` (`user_id`),
  ADD KEY `auditoria_created_at_index` (`created_at`);

--
-- Indices de la tabla `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`);

--
-- Indices de la tabla `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`);

--
-- Indices de la tabla `conductores`
--
ALTER TABLE `conductores`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `conductores_token_unique` (`token`),
  ADD UNIQUE KEY `idx_conductor_token` (`token`),
  ADD KEY `idx_conductor_last_location` (`last_location_at`);

--
-- Indices de la tabla `item_reportes`
--
ALTER TABLE `item_reportes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `item_reportes_reporte_id_producto_id_unique` (`reporte_id`,`producto_id`),
  ADD KEY `idx_item_producto` (`producto_id`),
  ADD KEY `idx_resumen_productos` (`reporte_id`,`producto_id`,`cantidad`);

--
-- Indices de la tabla `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `productos_nombre_unique` (`nombre`);

--
-- Indices de la tabla `reporte_entregas`
--
ALTER TABLE `reporte_entregas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reporte_entregas_estado_index` (`estado`),
  ADD KEY `reporte_entregas_fecha_entrega_index` (`fecha_entrega`),
  ADD KEY `reporte_entregas_distrito_index` (`distrito`),
  ADD KEY `reporte_entregas_conductor_id_index` (`conductor_id`),
  ADD KEY `reporte_entregas_created_by_foreign` (`created_by`),
  ADD KEY `idx_fecha_estado` (`fecha_entrega`,`estado`),
  ADD KEY `idx_fecha_vendedor` (`fecha_entrega`,`created_by`),
  ADD KEY `idx_fecha_distrito` (`fecha_entrega`,`distrito`),
  ADD KEY `idx_produccion_fecha_estado_turno` (`fecha_entrega`,`estado_produccion`,`turno_entrega`),
  ADD KEY `idx_estado_created` (`estado_produccion`,`created_at`),
  ADD KEY `idx_nombre_cliente` (`nombre_cliente`);

--
-- Indices de la tabla `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoria`
--
ALTER TABLE `auditoria`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1036;

--
-- AUTO_INCREMENT de la tabla `conductores`
--
ALTER TABLE `conductores`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `item_reportes`
--
ALTER TABLE `item_reportes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=191;

--
-- AUTO_INCREMENT de la tabla `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT de la tabla `reporte_entregas`
--
ALTER TABLE `reporte_entregas`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=107;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `item_reportes`
--
ALTER TABLE `item_reportes`
  ADD CONSTRAINT `item_reportes_producto_id_foreign` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`),
  ADD CONSTRAINT `item_reportes_reporte_id_foreign` FOREIGN KEY (`reporte_id`) REFERENCES `reporte_entregas` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `reporte_entregas`
--
ALTER TABLE `reporte_entregas`
  ADD CONSTRAINT `reporte_entregas_conductor_id_foreign` FOREIGN KEY (`conductor_id`) REFERENCES `conductores` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reporte_entregas_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
