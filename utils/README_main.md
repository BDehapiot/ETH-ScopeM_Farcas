## Usage

Open a two channels hyperstack, where C1 will be used to normalize C2, and run the macro as describe above.

### Parameters
- `Furrow ROI scaling factor` (*float*): Scaling factor to adjust the size of the cleavage furrow ROI.

### Procedure
- Open hyperstack
- Run the macro
- Adjust parameters 
- Select z-plane of interest
- Draw mother and daughter cell ROIs
- Indicate cleavage furrow position

## Outputs
The following outputs will be saved in folder your folder containing the opened hyperstack. 

### Images
```bash
- C1_raw.tif    # C1 raw image of the selected z-plane.
- C2_raw.tif    # C2 raw image of the selected z-plane.
- C1_norm.tif   # C1 image normalized to the median value of membrane signal.
- C2_norm.tif   # C2 image normalized to the median value of membrane signal.
- C2C1.tif      # C2_norm divided by C1_norm. 
```

### CSV files

- `Results.csv`
```bash
- C1_med               # C1 median value of membrane signal
- C2_med               # C2 median value of membrane signal
- C1_norm_furrow_med   # C1 median furrow normalized signal
- C2_norm_furrow_med   # C2 median furrow normalized signal
- C2C1_furrow_med      # C2_norm/C1_norm ratio furrow signal
```

- `Profiles.csv`
```bash
- 1st column   # Distance in µm
- 2nd column   # Furrow line profile of C1 median furrow normalized signal
- 3rd column   # Furrow line profile of C2 median furrow normalized signal
- 4th column   # Furrow line profile of C2_norm/C1_norm ratio furrow signal
```

### ROIs

- `RoiSet.zip`
```bash
- mother_cell     # Drawn mother cell ROI
- daughter_cell   # Drawn daughter cell ROI
- furrow_points   # Drawn furrow points
- furrow_line     # Line profile ROI (inferred from furrow points)
- furrow_area     # Line area ROI (inferred from furrow points)
```