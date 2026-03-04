import { Component, OnInit, ViewChild, Output, EventEmitter } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { InterventionService } from '../../_services/affaires/intervention.service';
import { TechnicienService } from '../../_services/techniciens/technicien.service';
import { EquipeTechniciensService } from '../../_services/techniciens/equipe-techniciens.service';
import { SharedModule } from '../../_globale/shared/shared.module';
import { ModalSaveComponent } from '../modal-save/modal-save.component';

@Component({
  selector: 'app-details',
  standalone: true,
  imports: [CommonModule, FormsModule, SharedModule, ModalSaveComponent],
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.css']
})
export class DetailsComponent implements OnInit {
  @ViewChild('modalSave') modalSave!: ModalSaveComponent;
  @Output() clientAdded = new EventEmitter<void>();
  @Output() clientUpdated = new EventEmitter<void>();

  intervention: any = {};
  interventionItems: any[] = [];
  interventionId!: number;

  typeAffectation: 'equipe' | 'techniciens' = 'techniciens';
  selectedEquipeId: number | null = null;
  selectedTechniciens: number[] = [];
  equipes: any[] = [];
  techniciens: any[] = [];
  planning = { date: '', heure: '' };
  intervention_historique: any;
  newEtat: string = '';

  constructor(
    private technicienService: TechnicienService,
    private equipeTechniciensService: EquipeTechniciensService,
    private interventionService: InterventionService,
    private route: ActivatedRoute,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.interventionId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadData();
    this.loadHistorique(this.interventionId);
  }

  /** ==================== Chargement des données ==================== */
  loadData() {
    this.loadIntervention();
    this.loadTechniciens();
    this.loadEquipes();
  }

  loadIntervention() {
    this.interventionService.getItemById(this.interventionId).subscribe(res => {
      this.intervention = res || {};
      this.intervention.techniciens = this.intervention.techniciens || [];
      this.intervention.equipe = this.intervention.equipe || null;
    });
  }

  loadTechniciens() {
    this.technicienService.getAll().subscribe(res => {
      this.techniciens = res as any[] || [];
    });
  }

  loadEquipes() {
    this.equipeTechniciensService.getAllEquipes().subscribe({
      next: (res: any) => this.equipes = res?.data || [],
      error: err => console.error('Erreur chargement équipes', err)
    });
  }

  /** ==================== Historique et timeline ==================== */
  loadHistorique(id: number) {
    this.interventionService.getInterventionDetails(id).subscribe({
      next: (data) => {
        this.intervention_historique = data;
        this.buildTimeline(data);
      },
      error: (err) => console.error(err)
    });
  }

  buildTimeline(data: any) {
    const items: any[] = [];

    // Début intervention
    if (data.date_debut_intervention) {
      items.push({
        date: this.combineDateTime(data.date_debut_intervention, data.heure_debut_intervention_h, data.heure_debut_intervention_min),
        title: 'Début de l’intervention',
        type: 'text',
        content: `Début à ${data.heure_debut_intervention_h || 0}h${(data.heure_debut_intervention_min || 0).toString().padStart(2, '0')}`
      });
    }

    // Photos avant travaux
    if (data.photos?.before?.length) {
      items.push({
        date: data.photos.before[0]?.captured_at,
        title: 'Photos avant travaux',
        type: 'photo',
        content: data.photos.before.map((p: any) => p.url)
      });
    }

    // Interruptions
    if (data.interruptions?.length) {
      data.interruptions.forEach((int: any) => {
        items.push({
          date: int.started_at,
          title: 'Interruption',
          type: 'text',
          content: `${int.custom_reason || int.reason || '—'} (${int.duration_minutes || 0} min)`
        });
      });
    }

    // Photos après travaux
    if (data.photos?.after?.length) {
      items.push({
        date: data.photos.after[0]?.captured_at,
        title: 'Photos après travaux',
        type: 'photo',
        content: data.photos.after.map((p: any) => p.url)
      });
    }

    // Signatures
    if (data.signatures?.client?.signature_data) {
      items.push({
        date: data.signatures.client.signed_at,
        title: 'Signature Client',
        type: 'signature',
        content: [`data:image/png;base64,${data.signatures.client.signature_data}`]
      });
    }

    if (data.signatures?.technician?.signature_data) {
      items.push({
        date: data.signatures.technician.signed_at,
        title: 'Signature Technicien',
        type: 'signature',
        content: [`data:image/png;base64,${data.signatures.technician.signature_data}`]
      });
    }

    // Fin intervention
    if (data.date_fin_intervention) {
      items.push({
        date: this.combineDateTime(data.date_fin_intervention, data.heure_fin_intervention_h, data.heure_fin_intervention_min),
        title: 'Fin de l’intervention',
        type: 'table',
        content: ['Trajet Aller', 'Intervention', 'Trajet Retour'],
        checked: [false, true, false]
      });
    }

    // Tri chronologique
    this.interventionItems = items.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  }

  combineDateTime(date: string, hour: number, minute: number): Date {
    const h = hour || 0;
    const m = minute || 0;
    return new Date(`${date}T${this.pad(h)}:${this.pad(m)}:00`);
  }

  pad(value: number): string {
    return value.toString().padStart(2, '0');
  }

  /** ==================== Calcul durée réelle ==================== */
  getRealInterventionDuration(): string {
    if (!this.intervention.date_debut_intervention || !this.intervention.date_fin_intervention) return '-';

    const hStart = Number(this.intervention.heure_debut_intervention_h ?? 0);
    const mStart = Number(this.intervention.heure_debut_intervention_min ?? 0);
    const hEnd = Number(this.intervention.heure_fin_intervention_h ?? 0);
    const mEnd = Number(this.intervention.heure_fin_intervention_min ?? 0);

    const start = new Date(`${this.intervention.date_debut_intervention}T${this.pad(hStart)}:${this.pad(mStart)}:00`);
    const end = new Date(`${this.intervention.date_fin_intervention}T${this.pad(hEnd)}:${this.pad(mEnd)}:00`);

    let diffMs = end.getTime() - start.getTime();
    if (diffMs < 0) return '-';

    const hours = Math.floor(diffMs / (1000 * 60 * 60));
    diffMs -= hours * 1000 * 60 * 60;
    const minutes = Math.floor(diffMs / (1000 * 60));

    return `${hours} h ${minutes} min`;
  }

  /** ==================== Affectation ==================== */
  assign() {
    if (this.typeAffectation === 'techniciens') {
      this.interventionService.assignTechniciens(this.interventionId, this.selectedTechniciens).subscribe({
        next: () => { alert('Techniciens affectés avec succès !'); this.loadIntervention(); },
        error: err => { console.error(err); alert('Erreur lors de l\'affectation des techniciens'); }
      });
    } else if (this.typeAffectation === 'equipe' && this.selectedEquipeId) {
      this.interventionService.assignEquipe(this.interventionId, this.selectedEquipeId).subscribe({
        next: () => { alert('Équipe affectée avec succès !'); this.loadIntervention(); },
        error: err => { console.error(err); alert('Erreur lors de l\'affectation de l\'équipe'); }
      });
    }
  }

  addPlanning() {
    if (!this.planning.date || !this.planning.heure) return;
    this.interventionService.addPlanning(this.interventionId, { ...this.planning }).subscribe({
      next: () => { alert('Planning ajouté avec succès'); this.planning = { date: '', heure: '' }; this.loadIntervention(); },
      error: err => console.error(err)
    });
  }

  editIntervention(id: number) { this.router.navigate(['/interventions/edit', id]); }

  deleteIntervention(id: number) {
    if (!id) return;
    if (!confirm("Voulez-vous vraiment supprimer cette intervention ?")) return;

    this.interventionService.delete(id).subscribe({
      next: () => { alert("Intervention supprimée avec succès ✅"); this.router.navigate(['/interventions/list']); },
      error: err => { console.error("Erreur lors de la suppression", err); alert("Erreur lors de la suppression ❌"); }
    });
  }

  updateEtat(): void {
    if (!this.newEtat) return;
    this.interventionService.updateType(this.intervention.id, this.newEtat).subscribe({
      next: () => { this.intervention.etat = this.newEtat; this.newEtat = ''; },
      error: err => console.error('Erreur lors de la mise à jour de l’état :', err)
    });
  }

  getBadgeClass(etat: string): string {
    switch (etat) {
      case 'en_cours': return 'bg-primary';
      case 'terminee': return 'bg-success';
      case 'annulee': return 'bg-danger';
      case 'prevue': return 'bg-info';
      case 'terminee_avec_interruption': return 'bg-warning text-dark';
      case 'terminee_avec_succes': return 'bg-success';
      case 'trajet_en_cours': return 'bg-info';
      case 'pause': return 'bg-secondary';
      case 'refusee': return 'bg-danger';
      default: return 'bg-secondary';
    }
  }

  formatEtat(etat: string | null | undefined): string {
    if (!etat) return '—';
    return etat.replace(/_/g, ' ').replace(/^\w/, c => c.toUpperCase());
  }

  modePlanification(intervention: any) {
    if (this.modalSave) {
      this.modalSave.initializeModal(intervention);
    } else {
      console.error('ModalSaveComponent non initialisé !');
    }
  }

  editPlanning() { this.router.navigate(['/interventions/planning']); }
}