import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { InterventionService } from '../../_services/affaires/intervention.service';
import Modal from 'bootstrap/js/dist/modal';

import { SharedModule } from '../../_globale/shared/shared.module';
import { ModalSaveComponent } from '../modal-save/modal-save.component';

@Component({
  selector: 'app-list',
  standalone: true,
  imports: [
    CommonModule,   // ✅ ngIf, ngFor, ngClass, date pipe
    FormsModule,    // ✅ ngModel
    RouterModule,    // ✅ routerLink
    ModalSaveComponent,
    SharedModule
  ],
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.css']
})


export class ListComponent implements OnInit {

  @ViewChild('modalSave') modalSave!: ModalSaveComponent;

  interventions: any[] = [];
  searchTerm = '';

  // Pagination
  currentPage = 1;
  limit = 20;
  totalPages = 1;
  pages: number[] = [];

  constructor(
    private interventionService: InterventionService,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.loadInterventions();
  }

  // ===================== INTERVENTIONS =====================
  loadInterventions(page: number = 1, search: string = '') {
    this.interventionService.getAllPaginated(page, this.limit, search)
      .subscribe((res: any) => {
        this.interventions = res.data;
        this.currentPage = res.page;
        this.totalPages = Math.ceil(res.total / res.limit);
        this.pages = Array.from({ length: this.totalPages }, (_, i) => i + 1);
      });
  }

  searchInterventions() {
    this.loadInterventions(1, this.searchTerm);
  }

  changePage(page: number) {
    if (page < 1 || page > this.totalPages) return;
    this.loadInterventions(page, this.searchTerm);
  }

  // ===================== NAVIGATION =====================
  goToAddIntervention() {
    this.router.navigate(['/interventions']);
  }

  openDetail(id: number) {
    this.router.navigate(['/interventions/details', id]);
  }

  editIntervention(id: number) {
    this.router.navigate(['/interventions/edit', id]);
  }

  deleteIntervention(id: number) {
    if (!confirm('Supprimer cette intervention ?')) return;
    this.interventionService.delete(id).subscribe(() => {
      this.loadInterventions(this.currentPage, this.searchTerm);
    });
  }

  // ===================== DUPLICATION =====================
  duplicate(intervention: any) {
    const confirmation = confirm(
      `Voulez-vous vraiment dupliquer l’intervention N°${intervention.numero} ?`
    );
    if (!confirmation) return;

    const maxNumero = Math.max(...this.interventions.map(i => i.numero || 0));
    const nouveauNumero = maxNumero + 1;

    const nouvelleIntervention = {
      ...intervention,
      id: undefined,
      numero: nouveauNumero,
      titre: intervention.titre + ' (Copie)',
      etat: 'brouillon',
      date_prevue: null,
      date_debut_prevue: null,
      date_fin_prevue: null,
      duree_prevue_heures: 0,
      duree_prevue_minutes: 0
    };

    this.interventionService.create(nouvelleIntervention).subscribe({
      next: () => this.loadInterventions(),
      error: err => console.error('Erreur duplication', err)
    });
  }

  // Liste des états
  etatsConfig: any[] = [
    { value: 'en_cours', label: 'En cours', class: 'bg-primary', icon: 'mdi mdi-timer-sand' },
    { value: 'annulee', label: 'Annulée', class: 'bg-danger', icon: 'mdi mdi-close-circle' },
    { value: 'prevue', label: 'Prévue', class: 'bg-info', icon: 'mdi mdi-calendar' },
    { value: 'trajet_en_cours', label: 'Trajet en cours', class: 'bg-info', icon: 'mdi mdi-car' },
    { value: 'pause', label: 'Pause', class: 'bg-secondary', icon: 'mdi mdi-pause-circle' },
    { value: 'refusee', label: 'Refusée', class: 'bg-danger', icon: 'mdi mdi-cancel' },
    { value: 'terminee_avec_succes', label: 'Terminée avec succès', class: 'bg-success', icon: 'mdi mdi-star-circle' },
    { value: 'terminee_avec_interruption', label: 'Terminée avec interruption', class: 'bg-warning text-dark', icon: 'mdi mdi-alert-circle' },
  ];
  selectedIntervention: any = null;

  // Méthodes pour badges et icônes
  getEtatConfig(etat: string) {
    return this.etatsConfig.find(e => e.value === etat);
  }

  getBadgeClass(etat: string): string {
    return this.getEtatConfig(etat)?.class || 'bg-secondary';
  }

  getEtatIcon(etat: string): string {
    return this.getEtatConfig(etat)?.icon || 'mdi mdi-help-circle';
  }

  // Sélection d'une intervention (modal ou autre)
  onSelectIntervention(intervention: any) {
    if (this.modalSave) {
      this.modalSave.initializeModal(intervention);
    } else {
      console.error('ModalSaveComponent non initialisé !');
    }
  }

  onModalClose() {
    this.selectedIntervention = null;
  }

  /**
   * Transforme le tableau de techniciens en une chaîne de caractères lisible
   * pour l'attribut 'title' (infobulle au survol)
   */
  getTechNames(techniciens: any[]): string {
    if (!techniciens || techniciens.length === 0) {
      return 'Aucun technicien assigné';
    }
    // Crée une liste : "Idomnis Iste, Et voluptatem Sapiente..."
    return techniciens
      .map(t => `${t.prenom} ${t.nom}`)
      .join(', ');
  }

}
