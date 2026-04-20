import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class MotCleLiensService {

  // URL basée sur ton architecture : http://localhost:3005/api/v1/affaires/mot-cle-liens
  private baseUrl = environment.url_affaire + '/affaires/mot-cle-liens';

  constructor(private http: HttpClient) { }

  /** * Lier un mot-clé à une cible (Affaire ou Intervention)
   * record: { mot_cle_id: number, target_id: number, target_type: 'AFFAIRE' | 'INTERVENTION' }
   */
  create(record: any): Observable<any> {
    return this.http.post(this.baseUrl, record);
  }

  /** * Récupérer tous les liens enregistrés (tous types confondus)
   */
  getAll(): Observable<any> {
    return this.http.get(this.baseUrl);
  }

  /** * Récupérer un lien spécifique par son ID unique
   */
  getById(id: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/${id}`);
  }

  /** * Modifier un lien existant
   */
  update(id: number, record: any): Observable<any> {
    return this.http.put(`${this.baseUrl}/${id}`, record);
  }

  /** * Supprimer un lien (Détacher le mot-clé de l'objet)
   */
  delete(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/${id}`);
  }

  /** * 🔍 Récupérer tous les mots-clés liés à une cible spécifique
   * @param targetType 'AFFAIRE' ou 'INTERVENTION'
   * @param targetId L'ID de l'affaire ou de l'intervention
   */
  getByTarget(targetType: 'AFFAIRE' | 'INTERVENTION', targetId: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/target/${targetType}/${targetId}`);
  }

}