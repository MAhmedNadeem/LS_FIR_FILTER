#include <iostream>
#include <vector>
#include <cmath>
#include <iomanip>
#include <fstream>
#include <cstdint> 

using namespace std;

const int NUM_TAPS = 73;
const int NUM_SAMPLES = 100; 
const float coeff_float[NUM_TAPS] = {
    0.025804122, 0.020552684, 0.028396631, 0.037923047, 0.049296639, 0.062671826, 0.078188509,
    0.095967794, 0.116107786, 0.138679546, 0.163723333, 0.191245225, 0.221214225, 0.253559961,
    0.288171034, 0.324894126, 0.363533898, 0.403853725, 0.445577304, 0.488391123, 0.53194777,
    0.575870065, 0.61975593, 0.663183933, 0.705719403, 0.746921012, 0.786347677, 0.82356567,
    0.858155769, 0.889720317, 0.917890027, 0.942330394, 0.962747575, 0.978893597, 0.990570797,
    0.997635377, 1.0, 0.997635377, 0.990570797, 0.978893597, 0.962747575, 0.942330394, 0.917890027,
    0.889720317, 0.858155769, 0.82356567, 0.786347677, 0.746921012, 0.705719403, 0.663183933,
    0.61975593, 0.575870065, 0.53194777, 0.488391123, 0.445577304, 0.403853725, 0.363533898,
    0.324894126, 0.288171034, 0.253559961, 0.221214225, 0.191245225, 0.163723333, 0.138679546,
    0.116107786, 0.095967794, 0.078188509, 0.062671826, 0.049296639, 0.037923047, 0.028396631,
    0.020552684, 0.025804122
};

int main() {
    vector<int16_t> coeff_fixed(NUM_TAPS);
    vector<int16_t> input_fixed(NUM_SAMPLES);
    vector<int16_t> output_fixed(NUM_SAMPLES);

    cout << "Fixed Point Coefficients (Q2.14)" << endl;
    for (int i = 0; i < NUM_TAPS; i++) {
        coeff_fixed[i] = round(coeff_float[i] * 16384.0f);
    }

    cout << "100 Input Samples (Q3.10)" << endl;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        float sample = 1.0 * sin(2 * M_PI * 0.05 * i) + 0.5 * sin(2 * M_PI * 0.4 * i);
        
        input_fixed[i] = round(sample * 1024.0f); 
    }

    for (int n = 0; n < NUM_SAMPLES; n++) {
        int64_t accumulator = 0; 
        
        for (int k = 0; k < NUM_TAPS; k++) {
            if (n - k >= 0) {
                accumulator += (int32_t)input_fixed[n - k] * (int32_t)coeff_fixed[k];
            }
        }

        output_fixed[n] = (int16_t)(accumulator >> 11);
    }

    cout << "\nSample\tInput(Q3.10)\tOutput(Q3.13)" << endl;
    cout << "----------------------------------------" << endl;
    for (int i = 0; i < 20; i++) { 
        cout << i << "\t" 
             << input_fixed[i] << "\t\t" 
             << output_fixed[i] << endl;
    }
    
    ofstream infile("input_samples.txt");
for (int i = 0; i < NUM_SAMPLES; i++) {
    infile << hex << setw(4) << setfill('0') << (input_fixed[i] & 0xFFFF) << endl;
}
infile.close();
    cout << "\n100 outputs written to 'golden_reference_out.txt' in hex format." << endl;

    return 0;
}