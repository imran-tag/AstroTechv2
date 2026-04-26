import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class InterventionService {

  private baseUrl = environment.url_affaire + '/affaires/interventions';

  constructor(private http: HttpClient) { }

  /** Ajouter une intervention (FormData autorisé) */
  create(record: any): Observable<any> {
    return this.http.post(this.baseUrl, record);
  }

  /** Modifier une intervention */
  update(id: number, record: any): Observable<any> {
    return this.http.put(`${this.baseUrl}/${id}`, record);
  }

  /** Récupérer toutes les interventions */
  getAll(): Observable<any> {
    return this.http.get(`${this.baseUrl}/all`);
  }

  getAllPaginated(page: number, limit: number, search: string) {
    return this.http.get<any[]>(`${this.baseUrl}`, {
      params: {
        page: page.toString(),
        limit: limit.toString(),
        search
      }
    });
  }

  /** Récupérer une intervention par ID */
  getItemById(id: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/${id}`);
  }

  /** Supprimer une intervention */
  delete(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/${id}`);
  }

  /** Obtenir le prochain numéro automatique */
  getNextNumero(): Observable<any> {
    return this.http.get(`${this.baseUrl}/nextNumero`);
  }

  /** Assigner techniciens à une intervention */
  assignTechniciens(interventionId: number, techniciens: number[]): Observable<any> {
    return this.http.post(
      `${this.baseUrl}/${interventionId}/assign-techniciens`,
      { techniciens }
    );
  }

  /** Ajouter un planning dans une intervention */
  addPlanning(interventionId: number, planning: any): Observable<any> {
    return this.http.post(
      `${this.baseUrl}/${interventionId}/add-planning`,
      planning
    );
  }

  // ✅ Affecter une équipe à une intervention
  assignEquipe(interventionId: number, equipeId: number) {
    return this.http.put(`${this.baseUrl}/${interventionId}/assign-equipe`, {
      equipe_id: equipeId
    });
  }

  // Supprimer une équipe par ID
  deleteEquipe(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/equipe/${id}`);
  }

  updateType(interventionId: number, type: string): Observable<any> {
    return this.http.put(
      `${this.baseUrl}/${interventionId}/type`,
      { type }
    );
  }

  getByTypePaginated(
    typeId: number,
    page: number,
    limit: number,
    etat: string = ''   // 🔹 correspond à req.query.etat
  ) {
    return this.http.get<{
      success: boolean;
      data: any[];
      pagination: {
        page: number;
        limit: number;
        total: number;
        totalPages: number;
      };
    }>(`${this.baseUrl}/by-type/${typeId}`, {
      params: {
        page: page.toString(),
        limit: limit.toString(),
        etat   // 🔹 le backend utilisera req.query.estat
      }
    });
  }

  getInterventionTypes() {
    return this.http.get(`${this.baseUrl}/type/all`);
  }

  addPrevision(interventionId: number, data: { date_debut: string, duree_heures: number, duree_minutes: number }): Observable<any> {
    return this.http.post(`${this.baseUrl}/${interventionId}/add-prevision`, data);
  }

  getInterventionDetails(id: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/${id}/details`);
  }

  getInterventionRecap(id: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/${id}/recap`);
  }

}