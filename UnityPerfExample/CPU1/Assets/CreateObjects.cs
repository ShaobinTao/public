using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateObjects : MonoBehaviour {

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {

		for (int i = 0; i < 100; i++) {
			GameObject	obj = GameObject.CreatePrimitive (PrimitiveType.Sphere);

			float x = Random.Range (0.0f, 50.0f);
			float y = Random.Range (0.0f, 50.0f);
			float z = Random.Range (0.0f, 50.0f);
			obj.transform.localPosition = new Vector3 (x, y, z);

			obj.SetActive(false);

			Destroy (obj, 1);
		}



	}
}
