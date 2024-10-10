SELECT name, tyrell.get_kingdom_size(gid) AS area_km2
FROM atlas.kingdoms
ORDER BY area_km2 DESC
LIMIT 1 OFFSET 2;  -- Þetta sleppir tveimur fyrstu (stærstu) og gefur þriðja stærsta konungssvæðið