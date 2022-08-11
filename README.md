# Adversarial attacks against blind image quality models

This files includes instructions for reproducing the results for white-box model in Section 4 of the paper: _J. Korhonen, J. You: "Adversarial Attacks against Blind Image Quality Assessment Models", QoEVMA'22_. 

This package contains the following Matlab files:

readme.txt (this file)
makeSmallSpaq.m (resizing SPAQ images to 512x384 resolution)
trainSubstituteModel.m (training the substitute BIQA model)
generateAdversaryImage.m (adversarial image generator)
generateAdversarialExamples.m (generating adversarial examples)
generateResults.m (generating results with the substitute model)
displayResults.m (displaying results)

PRELIMINARIES
-----------------------------------------------------------------
Tested with Matlab R2021b (Windows10). Requires deep learning toolbox, image processing toolbox, pretrained resnet50, and parallel processing toolbox (optional; only required for using GPU for deep learning). These can be installed using the standard Matlab add-on tool.

KoNIQ-10k dataset is required for training the substitute BIQA model (512x384 resolution version), can be downloaded from http://database.mmsp-kn.de/koniq-10k-database.html.

SPAQ dataset is required for generating the adversarial examples, can be downloaded from https://github.com/h4nwei/SPAQ. Note that we use 512x384 resolution version of the images, whereas the original dataset includes images with different resolutions. You can use Matlab script makeSmallSpaq.m in this package for downscaling the images.

TRAINING THE SUBSTITUTE MODEL
-----------------------------------------------------------------
Matlab script trainSubstituteModel.m can be used to train the substitute BIQA model, as described in the paper. KoNIQ-10k needs to be installed. You need to modify path on line 9 in the script for your path to the KoNIQ-10k images and metadata. The script saves the resulting model in file IQA_MODEL_01.mat.

Please note that random initialization of weights is used, and therefore the results may slightly change from those reported in the paper. There should not be dramatic differences, though.

GENERATING ADVERSARIAL EXAMPLES
-----------------------------------------------------------------
The adversarial image generator, described in the paper in Section 3, is implemented in Matlab script generateAdversaryImage.m. 

You can use script generateAdversarialExamples.mat to generate the adversarial examples described in Section 4. You need to modify spaq_folder on line 8 for the folder with SPAQ images (512x384 resolution), and out_folder on line 10 to the folder where you want to save the adversarial examples. In addition, you need to have the IQA_MODEL_01.mat in the same folder where you run the script.

COMPUTING THE RESULTS
-----------------------------------------------------------------
After you have generated the adversarial examples, you can compute the results for the substitute model by using script generateResults.m. You need to modify the folder on line 8 to the folder with your adversarial images, and file name on line 10 to be the results file where you want to store the results. The results file is a CSV file with format:

filename,predmos

where filename is the name of the adversarial image file, and predmos is the MOS predicted for the image.

Note that we have not included scripts for computing the results for the black-box models, since these rely on third-party implementations. However, it is relatively straightforward to modify e.g. Python implementations to produce those results, e.g. as follows:

*Change the right path here:* im_path = 'j:/adversarials/'

*Change the filename for the model:* e.g. 'hyperiqa_results.csv'

with open('j:/results.csv', 'w+') as f: 
    for filename in os.listdir(im_path):
        if filename.endswith(".png"):
            im_full_path = im_path + filename 

            # predict the score, this part is model specific
            score = model.predict(im_full_path) # e.g. ...
            
            # normalize to range 1-5, if the range is e.g. 0-100
            score = score/25 + 1 
 
            # write the file name and score in the results file
            print('%s, %1.4f' % (filename, score), file=f)


DISPLAYING THE RESULTS
-----------------------------------------------------------------
Matlab script for displaying the average results for different sets of adversarial images (e.g. low quality SPAQ, high quality SPAQ etc.) is in script displayResults.m. Modify the name of the results file on line 7. Note that the results for different models should be stored in different results files.
