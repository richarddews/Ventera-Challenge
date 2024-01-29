-- Challenge Requirement #1:
  SELECT version(); -- PostgreSQL 15.5
  CREATE EXTENSION postgis;
  SELECT PostGIS_Full_Version(); -- POSTGIS 3.4.1
  CREATE EXTENSION pointcloud;
  CREATE EXTENSION pointcloud_postgis;
  CREATE EXTENSION postgis_raster;
  ALTER DATABASE postgres SET postgis.enable_outdb_rasters = true;
  ALTER DATABASE postgres SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';

-- Challenge Requirement #3:
   -- raster2pgsql.exe -N -32767 -t 128x128 -c -I -C -M -d C:\users\richard\downloads\USGS_OPR_NC_Phase5_2018_A18_LA_37_00964920_.asc public.myrasters_lidar | psql -d postgres -h localhost -U postgres -p 5432
  
  CREATE TABLE myrasters_lidar(rid serial PRIMARY KEY, rast raster);
  SELECT count(*) FROM myrasters_lidar;
  SELECT ST_SummaryStats(rast)
    FROM myrasters_lidar ORDER BY rid LIMIT 5;
  SELECT ST_BandPixelType(rast, 1)
    FROM myrasters_lidar ORDER BY rid LIMIT 5;
-- Challenge Requirement #5:
   CREATE TABLE my_slope_lidar As
     SELECT ST_Slope(ST_Union(rast), 1, '32BF') As slope
       FROM myrasters_lidar;
-- Challenge Requirement #6:   
   CREATE TABLE my_cents_lidar As
      SELECT a.geom, a.val, a.x, a.y
        FROM (SELECT sp.* FROM my_slope_lidar, LATERAL ST_PixelAsCentroids(slope, 1) As sp) a;
-- Challenge Requirement #7:
   CREATE INDEX sidx_my_cents_lidar_geom ON public.my_cents_lidar USING gist (geom);
-- Challenge Requirement #8:
   SELECT ST_SummaryStatsAgg(rast, 1, TRUE) FROM myrasters_lidar; -- min: 0
   CREATE TABLE my_poly_lidar_min_val As
     SELECT val, geom
       FROM (SELECT dp.*
               FROM myrasters_lidar ml, 
               LATERAL ST_DumpAsPolygons(rast) As dp) As foo
       WHERE val = 0;
   SELECT count(*) FROM my_poly_lidar_min_val;

SELECT DISTINCT ST_SRID(geom) FROM my_cents_lidar ORDER BY 1; -- (geom): my_cents_lidar, my_poly_lidar_min_val     
SELECT UpdateGeometrySRID('my_cents_lidar','geom',990000);
SELECT ST_Transform(geom, 4326) FROM my_cents LIMIT 1; -- to show sample within DBeaver Value window properly

SELECT DISTINCT ST_SRID(rast) FROM myrasters_lidar ORDER BY 1; -- (slope): my_slope_lidar; (rast): myrasters_lidar
SELECT slope FROM myrasters_lidar LIMIT 1;
SELECT UpdateRasterSRID('myrasters_lidar','rast',990000);
      
INSERT INTO spatial_ref_sys (srid, proj4text)
VALUES (990000,
        '+proj=lcc +lat_0=33.75 +lon_0=-79 +lat_1=36.1666666666667 +lat_2=34.3333333333333 +x_0=609601.219202438 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=us-ft +vunits=us-ft +no_defs');
      
SELECT DISTINCT srid FROM spatial_ref_sys ORDER BY 1 DESC;