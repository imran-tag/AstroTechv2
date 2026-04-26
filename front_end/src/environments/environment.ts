// This file can be replaced during build by using the `fileReplacements` array.
// `ng build` replaces `environment.ts` with `environment.prod.ts`.
// The list of file replacements can be found in `angular.json`.

export const environment = {
  production: false,
  apiURL: "http://127.0.0.1:3000/api/v1",

  url_client: "http://localhost:3001/api/v1",
  url_fichier: "http://localhost:3002/api/v1",
  url_referent: "http://localhost:3003/api/v1",
  url_technicien: "http://localhost:3004/api/v1",
  url_affaire: "http://localhost:3005/api/v1",
  url_affaire_uploads: "http://localhost:3005/uploads",
  url_upload: "http://localhost:3002/uploads"
};

/*
 * For easier debugging in development mode, you can import the following file
 * to ignore zone related error stack frames such as `zone.run`, `zoneDelegate.invokeTask`.
 *
 * This import should be commented out in production mode because it will have a negative impact
 * on performance if an error is thrown.
 */
// import 'zone.js/plugins/zone-error';  // Included with Angular CLI.
