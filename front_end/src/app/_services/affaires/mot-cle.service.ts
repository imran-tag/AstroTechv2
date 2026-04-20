import { Injectable } from '@angular/core'; // Un seul import pour core
import { HttpClient } from '@angular/common/http'; // Un seul import pour http
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class MotCleService {

  // URL basée sur ton architecture : http://localhost:3005/api/v1/mots-cles
  private baseUrl = environment.url_affaire + '/affaires/mots-cles';

  constructor(private http: HttpClient) { }

  /** * Créer un nouveau mot-clé dans le dictionnaire 
   * @param libelle Le nom de l'étiquette (ex: "Urgent")
   */
  create(libelle: string): Observable<any> {
    return this.http.post(this.baseUrl, { libelle });
  }

  /** * Récupérer la liste de tous les mots-clés disponibles
   */
  getAll(): Observable<any> {
    return this.http.get(this.baseUrl);
  }

  /** * Récupérer un mot-clé spécifique par son ID
   */
  getById(id: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/${id}`);
  }

  /** * Modifier le nom d'un mot-clé existant
   */
  update(id: number, libelle: string): Observable<any> {
    return this.http.put(`${this.baseUrl}/${id}`, { libelle });
  }

  /** * Supprimer un mot-clé du dictionnaire
   */
  delete(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/${id}`);
  }
}