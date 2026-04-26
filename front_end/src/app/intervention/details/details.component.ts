import { Component, OnInit, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { InterventionService } from '../../_services/affaires/intervention.service';
import { TechnicienService } from '../../_services/techniciens/technicien.service';
import { EquipeTechniciensService } from '../../_services/techniciens/equipe-techniciens.service';
import { ModalSaveComponent } from '../modal-save/modal-save.component';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-details',
  standalone: true,
  imports: [CommonModule, FormsModule, ModalSaveComponent],
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.css']
})
export class DetailsComponent implements OnInit {
  @ViewChild('modalSave') modalSave!: ModalSaveComponent;

  intervention: any = null;
  interventionId!: number;
  interventionItems: any[] = [];
  recap: any = null;

  // Quick-action state
  newEtat: string = '';
  planning = { date: '', heure: '' };
  typeAffectation: string = 'techniciens';
  selectedEquipeId: string = '';
  selectedTechniciens: string[] = [];
  equipes: any[] = [];
  techniciens: any[] = [];

  readonly uploadsBase = environment.url_affaire_uploads;

  readonly securityLabels = [
    'Zone de travail balisée et sécurisée',
    'EPI portés (casque, gants, chaussures)',
    'Risques électriques vérifiés',
  ];
  readonly qualityLabels = [
    'Travaux conformes au bon de commande',
    'Zone nettoyée après intervention',
    'Client informé des travaux effectués',
  ];

  constructor(
    private interventionService: InterventionService,
    private technicienService: TechnicienService,
    private equipeTechniciensService: EquipeTechniciensService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.interventionId = Number(this.route.snapshot.paramMap.get('id'));
    if (this.interventionId) {
      this.loadData();
      this.loadRecap();
      this.loadEquipes();
      this.loadTechniciens();
    }
  }

  loadData() {
    this.interventionService.getItemById(this.interventionId).subscribe({
      next: (res) => {
        this.intervention = res;
        if (this.intervention) {
          this.intervention.techniciens = this.intervention.techniciens || [];
        }
      },
      error: (err) => console.error('Erreur chargement intervention', err)
    });
  }

  loadRecap() {
    this.interventionService.getInterventionRecap(this.interventionId).subscribe({
      next: (data) => { this.recap = data; },
      error: (err) => console.error('Erreur recap', err)
    });
  }

  loadEquipes() {
    this.equipeTechniciensService.getAllEquipes().subscribe({
      next: (data: any) => { this.equipes = data || []; },
      error: () => {}
    });
  }

  loadTechniciens() {
    this.technicienService.getAll().subscribe({
      next: (data: any) => { this.techniciens = data || []; },
      error: () => {}
    });
  }

  updateEtat() {
    if (!this.newEtat) return;
    this.interventionService.update(this.interventionId, { etat: this.newEtat }).subscribe({
      next: () => { this.loadData(); this.newEtat = ''; },
      error: (err) => console.error('Erreur update état', err)
    });
  }

  addPlanning() {
    if (!this.planning.date) return;
    this.interventionService.addPlanning(this.interventionId, this.planning).subscribe({
      next: () => { this.loadData(); this.planning = { date: '', heure: '' }; },
      error: (err) => console.error('Erreur ajout planning', err)
    });
  }

  assign() {
    if (this.typeAffectation === 'equipe' && this.selectedEquipeId) {
      this.interventionService.assignEquipe(this.interventionId, Number(this.selectedEquipeId)).subscribe({
        next: () => this.loadData(),
        error: (err) => console.error('Erreur affectation équipe', err)
      });
    } else if (this.typeAffectation === 'techniciens' && this.selectedTechniciens.length) {
      this.interventionService.assignTechniciens(this.interventionId, this.selectedTechniciens.map(Number)).subscribe({
        next: () => this.loadData(),
        error: (err) => console.error('Erreur affectation techniciens', err)
      });
    }
  }

  photoUrl(photo: any): string {
    const name = photo.file_path?.split(/[\\/]/).pop() || photo.file_name;
    return name ? `${this.uploadsBase}/photos/${name}` : '';
  }

  signatureUrl(sig: any): string {
    const name = sig.file_path?.split(/[\\/]/).pop();
    return name ? `${this.uploadsBase}/signatures/${name}` : '';
  }

  formatEtat(etat: string | null): string {
    if (!etat) return 'Non défini';
    return etat.replace(/_/g, ' ').toLowerCase().replace(/^\w/, c => c.toUpperCase());
  }

  getRealInterventionDuration(): string {
    if (this.intervention?.date_debut_intervention && this.intervention?.date_fin_intervention) {
      const start = new Date(this.intervention.date_debut_intervention);
      const end = new Date(this.intervention.date_fin_intervention);
      const diffMs = end.getTime() - start.getTime();
      const hours = Math.floor(diffMs / 3600000);
      const mins = Math.floor((diffMs % 3600000) / 60000);
      return `${hours}h ${mins}min`;
    }
    return '-';
  }

  editIntervention(id: number) { this.router.navigate(['/interventions/edit', id]); }

  deleteIntervention(id: number) {
    if (confirm('Supprimer cette intervention ?')) {
      this.interventionService.delete(id).subscribe(() => this.router.navigate(['/interventions/list']));
    }
  }

  modePlanification(interv: any) { this.modalSave?.initializeModal(interv); }

  editPlanning() { this.router.navigate(['/interventions/planning']); }

  pad(value: number): string { return value.toString().padStart(2, '0'); }

  getBadgeClass(etat: string | null): string {
    switch (etat) {
      case 'terminee':   return 'bg-success text-white';
      case 'en_cours':   return 'bg-primary text-white';
      case 'planifiee':  return 'bg-info text-white';
      case 'annulee':    return 'bg-danger text-white';
      default:           return 'bg-secondary text-white';
    }
  }
}
