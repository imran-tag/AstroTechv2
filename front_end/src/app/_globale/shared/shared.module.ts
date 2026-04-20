import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router'; // Plus simple d'exporter RouterModule
import { NgSelectModule } from '@ng-select/ng-select';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatInputModule } from '@angular/material/input';

@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule,
    NgSelectModule,
    //MatAutocompleteModule,
    MatInputModule,
    MatAutocompleteModule
  ],
  exports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule,    // Permet d'utiliser routerLink et router-outlet ailleurs
    NgSelectModule   // Permet d'utiliser <ng-select> dans tous vos composants
  ]
})
export class SharedModule { }