import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

interface AuthResponse {
  token: string;
  user: any;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private api = `${environment.url_client}/auth`;
  private currentUserSubject = new BehaviorSubject<any>(this.getUserFromStorage());
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {}

  // --- Méthodes existantes ---

  register(payload: { email: string; password: string; full_name?: string }) {
    return this.http.post<AuthResponse>(`${this.api}/register`, payload).pipe(
      tap(res => this.setSession(res))
    );
  }

  login(payload: { email: string; password: string }) {
    return this.http.post<AuthResponse>(`${this.api}/login`, payload).pipe(
      tap(res => this.setSession(res))
    );
  }

  logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    this.currentUserSubject.next(null);
  }

  // --- Nouvelles méthodes de mise à jour ---

  /**
   * Met à jour les infos de profil (nom, email)
   */
  updateProfile(payload: { full_name?: string; email?: string }): Observable<any> {
    return this.http.put(`${this.api}/profile`, payload).pipe(
      tap(() => {
        // On récupère les infos actuelles et on fusionne avec les nouvelles
        const currentUser = this.currentUserSubject.value;
        const updatedUser = { ...currentUser, ...payload };
        
        // Mise à jour du stockage local et du flux de données
        localStorage.setItem('user', JSON.stringify(updatedUser));
        this.currentUserSubject.next(updatedUser);
      })
    );
  }

  /**
   * Modifie le mot de passe
   */
  updatePassword(payload: { oldPassword: string; newPassword: string }): Observable<any> {
    return this.http.put(`${this.api}/password`, payload);
  }

  // --- Utilitaires ---

  isLoggedIn(): boolean {
    return !!localStorage.getItem('token');
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  private setSession(res: AuthResponse) {
    localStorage.setItem('token', res.token);
    localStorage.setItem('user', JSON.stringify(res.user));
    this.currentUserSubject.next(res.user);
  }

  private getUserFromStorage() {
    const u = localStorage.getItem('user');
    try {
      return u ? JSON.parse(u) : null;
    } catch (e) {
      return null;
    }
  }

fetchMe() {
  return this.http.get<{ user: any }>(`${this.api}/me`).pipe(
    tap({
      next: (res) => {
        if (res && res.user) {
          // 1. Persistance locale
          localStorage.setItem('user', JSON.stringify(res.user));
          // 2. Notification des composants abonnés (Navbar/Sidebar)
          this.currentUserSubject.next(res.user);
        }
      },
      error: (err) => {
        console.error('Erreur lors de la récupération du profil', err);
        // Optionnel : déconnexion si le token est invalide
        // this.logout(); 
      }
    })
  );
}
}