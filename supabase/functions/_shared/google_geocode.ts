/** @deprecated ใช้ google_places.ts — re-export เพื่อ backward compat */
export {
  type AutocompleteHit,
  type GeocodeHit,
  buildPlacesQuery,
  geocodeLocationByText,
  geocodeProjectByName,
  placesAutocomplete,
} from "./google_places.ts";
